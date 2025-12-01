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

class BleProvisioningRepositoryImpl implements BleProvisioningRepository {
  final BleClient _bleClient;
  final BleSecureCodecFactory _codecFactory;

  String? _deviceId;
  BleSecureCodec? _codec;
  int _mtu = 23; // default minimal MTU

  // Broadcast stream of all inner JSON responses from device.
  Stream<Map<String, dynamic>>? _innerStream;
  StreamSubscription<List<int>>? _notifySub;

  BleProvisioningRepositoryImpl(this._bleClient, this._codecFactory);

  bool get _isConnected => _deviceId != null && _codec != null;

  @override
  Future<void> connectToDevice({
    required String serialNumber,
    required String secureCode,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    // 1) Scan for advert with manufacturer data = 0xFFFF + serialNumber.
    final deviceId = await _findDeviceBySerial(serialNumber, timeout);
    _deviceId = deviceId;
    _codec = _codecFactory(secureCode);

    // 2) Connect + MTU + notifications subscription.
    await _bleClient.connect(deviceId);
    _mtu = await _bleClient.requestMtu(deviceId, 512);

    final rawNotifyStream = _bleClient.subscribeToCharacteristic(
      deviceId: deviceId,
      serviceUuid: _serviceUuid,
      characteristicUuid: _txCharUuid,
    );

    // Transform raw bytes -> string -> envelope json -> inner json.
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

    // 1) Send scan_start command.
    final innerReq = <String, dynamic>{
      'type': 'scan_start',
      'reqId': reqId,
      if (timeout != null) 'timeoutMs': timeout.inMilliseconds,
    };
    final transportJson = codec.encode(innerReq);
    await _writeJson(deviceId, transportJson);

    // 2) Collect results.
    final List<WifiNetwork> acc = [];
    final stream = _innerStream!.where((msg) => msg['reqId'] == reqId); // filter by reqId

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

    // 1) Send connect command.
    final innerReq = <String, dynamic>{
      'type': 'connect',
      'reqId': reqId,
      'ssid': ssid,
      'password': password,
      if (timeout != null) 'timeoutMs': timeout.inMilliseconds,
    };
    final transportJson = codec.encode(innerReq);
    await _writeJson(deviceId, transportJson);

    // 2) Listen for status updates.
    final stream = _innerStream!.where((msg) => msg['reqId'] == reqId && msg['type'] == 'status');

    await for (final msg in stream) {
      final status = WifiConnectStatus.fromJson(msg);
      yield status;

      if (status.state == WifiConnectState.success || status.state == WifiConnectState.failed) {
        break;
      }
    }
  }

  Future<String> _findDeviceBySerial(
    String serialNumber,
    Duration timeout,
  ) async {
    final adverts = _bleClient.scan();
    final completer = Completer<String>();

    late StreamSubscription sub;
    sub = adverts.listen((adv) {
      // Manufacturer data: we expect companyId = 0xFFFF.
      final data = adv.manufacturerData[0xFFFF];
      if (data == null || data.isEmpty) return;

      final sn = utf8.decode(data, allowMalformed: true);
      if (sn == serialNumber) {
        completer.complete(adv.deviceId);
        sub.cancel();
      }
    });

    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Device with SN $serialNumber not found'),
        );
        sub.cancel();
      }
    });

    return completer.future;
  }

  String _makeReqId(String prefix) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rnd = Random().nextInt(1000);
    return '${prefix}_${now}_$rnd';
  }

  Future<void> _writeJson(String deviceId, String json) async {
    final bytes = utf8.encode(json);
    final maxChunk = max(20, _mtu - 3); // safety for ATT headers.

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
