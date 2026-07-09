import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/ble_provisioning/data/ble/ble_client.dart';
import 'package:oshmobile/features/ble_provisioning/data/crypto/ble_secure_codec.dart';
import 'package:oshmobile/features/ble_provisioning/data/repositories/ble_provisioning_repository_impl.dart';
import 'package:oshmobile/features/ble_provisioning/domain/entities/wifi_connect_status.dart';

void main() {
  group('BleProvisioningRepositoryImpl', () {
    test('streams switching network sequence until success', () async {
      late final _FakeBleClient ble;
      ble = _FakeBleClient(
        onConnectRequest: (reqId) async {
          ble.emitStatus(
            reqId,
            state: 'connecting',
            message: 'switching_network',
          );
          ble.emitStatus(reqId, state: 'connecting', message: 'connecting');
          ble.emitStatus(reqId, state: 'connecting', message: 'obtaining_ip');
          ble.emitStatus(reqId, state: 'success', message: 'success');
        },
      );
      final repo = BleProvisioningRepositoryImpl(
        ble,
        (_) => const _JsonBleSecureCodec(),
      );

      await repo.connectToDevice(serialNumber: '9C139EB205F0', secureCode: '');

      final statuses = await repo
          .connectToWifi(ssid: 'Tele2_3088F6', password: 'password')
          .toList();

      expect(
        statuses.map((status) => status.state),
        [
          WifiConnectState.connecting,
          WifiConnectState.connecting,
          WifiConnectState.obtainingIp,
          WifiConnectState.success,
        ],
      );
      expect(
        statuses.map((status) => status.message),
        [
          'switching_network',
          'connecting',
          'obtaining_ip',
          'success',
        ],
      );
    });

    test('ends stream on terminal auth failure with reason', () async {
      late final _FakeBleClient ble;
      ble = _FakeBleClient(
        onConnectRequest: (reqId) async {
          ble.emitStatus(reqId, state: 'connecting', message: 'connecting');
          ble.emitStatus(
            reqId,
            state: 'failed',
            message: 'auth_failed',
            reason: 202,
          );
        },
      );
      final repo = BleProvisioningRepositoryImpl(
        ble,
        (_) => const _JsonBleSecureCodec(),
      );

      await repo.connectToDevice(serialNumber: '9C139EB205F0', secureCode: '');

      final statuses = await repo
          .connectToWifi(ssid: 'Tele2_3088F6', password: 'password')
          .toList();

      expect(
        statuses.map((status) => status.state),
        [
          WifiConnectState.connecting,
          WifiConnectState.failed,
        ],
      );
      expect(statuses.last.message, 'auth_failed');
      expect(statuses.last.reason, 202);
    });
  });
}

class _JsonBleSecureCodec implements BleSecureCodec {
  const _JsonBleSecureCodec();

  @override
  Map<String, dynamic> decode(String transportJson) {
    return jsonDecode(transportJson) as Map<String, dynamic>;
  }

  @override
  String encode(Map<String, dynamic> inner) {
    return jsonEncode(inner);
  }
}

class _FakeBleClient implements BleClient {
  _FakeBleClient({required this.onConnectRequest});

  final Future<void> Function(String reqId) onConnectRequest;
  final StreamController<List<int>> _notifyController =
      StreamController<List<int>>.broadcast();

  @override
  Stream<BleAdvertisement> scan() {
    return Stream<BleAdvertisement>.value(BleAdvertisement(
      deviceId: 'device-1',
      manufacturerData: {
        0xFFFF: Uint8List.fromList(utf8.encode('9C139EB205F0')),
      },
      localName: null,
    ));
  }

  @override
  Future<void> connect(String deviceId) async {}

  @override
  Future<int> requestMtu(String deviceId, int requested) async => 512;

  @override
  Stream<List<int>> subscribeToCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return _notifyController.stream;
  }

  @override
  Future<void> writeToCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List value,
  }) async {
    final request = jsonDecode(utf8.decode(value)) as Map<String, dynamic>;
    if (request['type'] != 'connect') {
      return;
    }

    final reqId = request['reqId'] as String;
    unawaited(Future<void>(() => onConnectRequest(reqId)));
  }

  void emitStatus(
    String reqId, {
    required String state,
    required String message,
    int? reason,
  }) {
    final payload = jsonEncode({
      'type': 'status',
      'reqId': reqId,
      'state': state,
      'message': message,
      if (reason != null) 'reason': reason,
    });
    _notifyController.add(utf8.encode(payload));
  }

  @override
  Future<void> disconnect(String deviceId) async {
    await _notifyController.close();
  }
}
