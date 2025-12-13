import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:oshmobile/core/utils/stream_waiters.dart';
import 'package:oshmobile/features/ble_provisioning/data/ble/ble_client.dart';
import 'package:oshmobile/features/ble_provisioning/data/crypto/ble_secure_codec.dart';
import 'package:oshmobile/features/ble_provisioning/domain/entities/wifi_connect_status.dart';
import 'package:oshmobile/features/ble_provisioning/domain/entities/wifi_network.dart';
import 'package:oshmobile/features/ble_provisioning/domain/repositories/ble_provisioning_repository.dart';

const _serviceUuid = 'efcdab90-7856-3412-efcd-ab9078563412';
const _txCharUuid = '95278333-6462-8423-9397-585326594131';
const _rxCharUuid = 'fedcba09-8765-4321-fedc-ba0987654321';
const _manufacturerCompanyId = 0xFFFF;
const Duration _nearbyTimeout = Duration(seconds: 3);

class BleProvisioningRepositoryImpl implements BleProvisioningRepository {
  final BleClient _bleClient;
  final BleSecureCodecFactory _codecFactory;

  String? _deviceId;
  BleSecureCodec? _codec;
  int _mtu = 23;

  Stream<Map<String, dynamic>>? _innerStream;
  StreamSubscription<List<int>>? _notifySub;

  /// SN -> deviceId cache (last seen)
  final Map<String, String> _lastSeenDeviceIdForSerial = {};

  /// Global "nearby" tracking
  final Set<String> _nearbySerials = {}; // devices currently considered "nearby"
  final Map<String, Timer> _disappearTimers = {}; // SN -> inactivity timer
  final Map<String, Set<StreamController<bool>>> _nearbyControllersBySerial = {};
  StreamSubscription<BleAdvertisement>? _globalScanSub;
  int _nearbyListeners = 0; // total active observeDeviceNearby listeners

  BleProvisioningRepositoryImpl(this._bleClient, this._codecFactory);

  bool get _isConnected => _deviceId != null && _codec != null && _innerStream != null;

  bool _advertMatchesSerial(BleAdvertisement adv, String serialNumber) {
    final data = adv.manufacturerData[_manufacturerCompanyId];
    if (data == null || data.isEmpty) return false;

    final sn = utf8.decode(data, allowMalformed: true);
    final isMatch = sn == serialNumber;

    if (isMatch) {
      _lastSeenDeviceIdForSerial[serialNumber] = adv.deviceId;
    }

    return isMatch;
  }

  @override
  Future<void> connectToDevice({
    required String serialNumber,
    required String secureCode,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_isConnected && _lastSeenDeviceIdForSerial[serialNumber] == _deviceId) {
      return;
    }

    await disconnect();

    final deviceId = await _findOrScanDeviceId(serialNumber, timeout);
    final codec = _codecFactory(secureCode);

    await _bleClient.connect(deviceId);
    _mtu = await _bleClient.requestMtu(deviceId, 512);

    final rawNotifyStream = _bleClient.subscribeToCharacteristic(
      deviceId: deviceId,
      serviceUuid: _serviceUuid,
      characteristicUuid: _txCharUuid,
    );

    final innerController = StreamController<Map<String, dynamic>>.broadcast();

    await _notifySub?.cancel();
    _notifySub = rawNotifyStream.listen(
      (chunk) {
        final currentCodec = _codec;
        if (currentCodec == null) return;

        try {
          final str = utf8.decode(chunk);
          final inner = currentCodec.decode(str);
          innerController.add(inner);
        } catch (e, st) {
          innerController.addError(e, st);
        }
      },
      onError: innerController.addError,
      onDone: innerController.close,
    );

    _deviceId = deviceId;
    _codec = codec;
    _innerStream = innerController.stream;
  }

  @override
  Future<void> disconnect() async {
    final id = _deviceId;
    if (id != null) {
      await _bleClient.disconnect(id);
    }
    await _notifySub?.cancel();
    _notifySub = null;
    _innerStream = null;
    _codec = null;
    _deviceId = null;
  }

  @override
  Stream<List<WifiNetwork>> scanWifiNetworks({Duration? timeout}) async* {
    if (!_isConnected || _innerStream == null) {
      throw StateError('BLE device is not connected');
    }

    final reqId = _makeReqId('scan');
    final codec = _codec!;
    final deviceId = _deviceId!;

    final innerReq = <String, dynamic>{
      'type': 'scan_start',
      'reqId': reqId,
      if (timeout != null) 'timeoutMs': timeout.inMilliseconds,
    };
    final transportJson = codec.encode(innerReq);
    await _writeJson(deviceId, transportJson);

    final acc = <WifiNetwork>[];
    final stream = _innerStream!.where((msg) => msg['reqId'] == reqId);

    await for (final msg in stream) {
      final type = msg['type'] as String? ?? '';
      if (type == 'scan_result') {
        acc.add(WifiNetwork.fromJson(msg));
        yield List.unmodifiable(acc);
      } else if (type == 'scan_done') {
        break;
      }
    }
  }

  @override
  Stream<WifiConnectStatus> connectToWifi({
    required String ssid,
    required String password,
    Duration? timeout,
  }) async* {
    if (!_isConnected || _innerStream == null) {
      throw StateError('BLE device is not connected');
    }

    final reqId = _makeReqId('conn');
    final codec = _codec!;
    final deviceId = _deviceId!;

    final innerReq = <String, dynamic>{
      'type': 'connect',
      'reqId': reqId,
      'ssid': ssid,
      'password': password,
      if (timeout != null) 'timeoutMs': timeout.inMilliseconds,
    };
    final transportJson = codec.encode(innerReq);
    await _writeJson(deviceId, transportJson);

    final stream = _innerStream!.where((msg) => msg['reqId'] == reqId && msg['type'] == 'status');

    await for (final msg in stream) {
      final status = WifiConnectStatus.fromJson(msg);
      yield status;

      if (status.state == WifiConnectState.success || status.state == WifiConnectState.failed) {
        break;
      }
    }
  }

  @override
  Stream<bool> observeDeviceNearby({required String serialNumber}) {
    final controller = StreamController<bool>();

    void emitCurrent() {
      if (!controller.isClosed) {
        controller.add(_nearbySerials.contains(serialNumber));
      }
    }

    controller.onListen = () {
      _nearbyListeners++;
      // Register this controller for given serial
      final set = _nearbyControllersBySerial.putIfAbsent(serialNumber, () => <StreamController<bool>>{});
      set.add(controller);

      // Ensure global scan is running
      _ensureGlobalScanStarted();

      // Emit current state (false by default)
      emitCurrent();
    };

    controller.onCancel = () async {
      _nearbyListeners = (_nearbyListeners - 1).clamp(0, 1 << 31);

      final set = _nearbyControllersBySerial[serialNumber];
      set?.remove(controller);
      if (set != null && set.isEmpty) {
        _nearbyControllersBySerial.remove(serialNumber);
      }

      if (_nearbyListeners == 0) {
        await _stopGlobalScan();
      }

      await controller.close();
    };

    return controller.stream;
  }

  void _ensureGlobalScanStarted() {
    if (_globalScanSub != null) return;

    _globalScanSub = _bleClient.scan().listen(
      (adv) {
        final data = adv.manufacturerData[_manufacturerCompanyId];
        if (data == null || data.isEmpty) return;

        final sn = utf8.decode(data, allowMalformed: true);
        if (sn.isEmpty) return;

        // Update last seen deviceId cache
        _lastSeenDeviceIdForSerial[sn] = adv.deviceId;

        // Mark as nearby
        final wasNearby = _nearbySerials.contains(sn);
        _nearbySerials.add(sn);

        // Reset disappear timer for this serial
        _disappearTimers[sn]?.cancel();
        _disappearTimers[sn] = Timer(_nearbyTimeout, () {
          _nearbySerials.remove(sn);
          _disappearTimers.remove(sn);
          _notifyNearbySerial(sn);
        });

        if (!wasNearby) {
          _notifyNearbySerial(sn);
        }
      },
      onError: (e, st) async {
        // On scan error we pessimistically mark all as "not nearby"
        final affected = _nearbySerials.toList();
        _nearbySerials.clear();
        for (final sn in affected) {
          _disappearTimers[sn]?.cancel();
          _disappearTimers.remove(sn);
          _notifyNearbySerial(sn);
        }

        await _globalScanSub?.cancel();
        _globalScanSub = null;

        // Try to restart scanning after small backoff if listeners are still present.
        if (_nearbyListeners > 0) {
          Future<void>.delayed(const Duration(seconds: 2), () {
            if (_nearbyListeners > 0 && _globalScanSub == null) {
              _ensureGlobalScanStarted();
            }
          });
        }
      },
      cancelOnError: false,
    );
  }

  Future<void> _stopGlobalScan() async {
    await _globalScanSub?.cancel();
    _globalScanSub = null;

    for (final timer in _disappearTimers.values) {
      timer.cancel();
    }
    _disappearTimers.clear();
    _nearbySerials.clear();
  }

  void _notifyNearbySerial(String serialNumber) {
    final controllers = _nearbyControllersBySerial[serialNumber];
    if (controllers == null || controllers.isEmpty) return;

    final value = _nearbySerials.contains(serialNumber);
    for (final c in controllers.toList()) {
      if (!c.isClosed) {
        c.add(value);
      }
    }
  }

  Future<String> _findOrScanDeviceId(
    String serialNumber,
    Duration timeout,
  ) async {
    final cachedId = _lastSeenDeviceIdForSerial[serialNumber];
    if (cachedId != null && cachedId.isNotEmpty) {
      return cachedId;
    }

    try {
      final adv = await firstWhereWithTimeout<BleAdvertisement>(
        _bleClient.scan(),
        (adv) => _advertMatchesSerial(adv, serialNumber),
        timeout,
        timeoutMessage: 'Device with SN $serialNumber not found',
      );
      return adv.deviceId;
    } on TimeoutException {
      // Keep a stable public error message.
      throw TimeoutException('Device with SN $serialNumber not found');
    }
  }


  String _makeReqId(String prefix) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rnd = Random().nextInt(1000);
    return '${prefix}_${now}_$rnd';
  }

  Future<void> _writeJson(String deviceId, String json) async {
    final bytes = utf8.encode(json);
    final maxChunk = max(20, _mtu - 3);

    for (var offset = 0; offset < bytes.length; offset += maxChunk) {
      final end = min(offset + maxChunk, bytes.length);
      final chunk = Uint8List.fromList(bytes.sublist(offset, end));
      await _bleClient.writeToCharacteristic(
        deviceId: deviceId,
        serviceUuid: _serviceUuid,
        characteristicUuid: _rxCharUuid,
        value: chunk,
      );
    }
  }
}
