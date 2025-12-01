import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

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

  BleProvisioningRepositoryImpl(this._bleClient, this._codecFactory);

  bool get _isConnected => _deviceId != null && _codec != null;

  bool _advertMatchesSerial(BleAdvertisement adv, String serialNumber) {
    final data = adv.manufacturerData[_manufacturerCompanyId];
    if (data == null || data.isEmpty) return false;

    final sn = utf8.decode(data, allowMalformed: true);
    return sn == serialNumber;
  }

  @override
  Future<void> connectToDevice({
    required String serialNumber,
    required String secureCode,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deviceId = await _findDeviceBySerial(serialNumber, timeout);
    _deviceId = deviceId;
    _codec = _codecFactory(secureCode);

    await _bleClient.connect(deviceId);
    _mtu = await _bleClient.requestMtu(deviceId, 512);

    final rawNotifyStream = _bleClient.subscribeToCharacteristic(
      deviceId: deviceId,
      serviceUuid: _serviceUuid,
      characteristicUuid: _txCharUuid,
    );

    final innerController = StreamController<Map<String, dynamic>>.broadcast();

    _notifySub = rawNotifyStream.listen(
        (chunk) {
          final str = utf8.decode(chunk);
          final codec = _codec;
          if (codec == null) return;
          final inner = codec.decode(str);
          innerController.add(inner);
        },
        onError: innerController.addError,
        onDone: () {
          innerController.close();
        });

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
  Stream<List<WifiNetwork>> scanWifiNetworks({
    Duration? timeout,
  }) async* {
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

    final List<WifiNetwork> acc = [];
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
  Stream<bool> observeDeviceNearby({required String serialNumber}) {
    final controller = StreamController<bool>();

    Timer? inactivityTimer;
    late final StreamSubscription<BleAdvertisement> sub;

    void emitIfChanged(bool value) {
      if (!controller.isClosed) {
        controller.add(value);
      }
    }

    void scheduleDisappear() {
      inactivityTimer?.cancel();
      inactivityTimer = Timer(_nearbyTimeout, () {
        emitIfChanged(false);
      });
    }

    controller.onListen = () {
      emitIfChanged(false);

      sub = _bleClient.scan().listen(
        (adv) {
          final isMatch = _advertMatchesSerial(adv, serialNumber);

          if (isMatch) {
            emitIfChanged(true);
            scheduleDisappear();
          }
        },
        onError: (e, st) {
          if (!controller.isClosed) {
            controller.addError(e, st);
          }
        },
      );
    };

    controller.onCancel = () async {
      await sub.cancel();
      inactivityTimer?.cancel();
      inactivityTimer = null;
      await controller.close();
    };

    return controller.stream;
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

  Future<String> _findDeviceBySerial(String serialNumber, Duration timeout) async {
    try {
      final adv = await _bleClient.scan().firstWhere((adv) => _advertMatchesSerial(adv, serialNumber)).timeout(timeout);
      return adv.deviceId;
    } on TimeoutException {
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
