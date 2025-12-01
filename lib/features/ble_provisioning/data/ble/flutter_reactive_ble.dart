import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:oshmobile/features/ble_provisioning/data/ble/ble_client.dart';

class ReactiveBleClientImpl implements BleClient {
  final FlutterReactiveBle _ble;

  StreamSubscription<ConnectionStateUpdate>? _connSub;

  ReactiveBleClientImpl(this._ble);

  @override
  Stream<BleAdvertisement> scan() {
    return _ble.scanForDevices(
      withServices: const [],
      scanMode: ScanMode.lowLatency,
    ).map((d) {
      final md = <int, Uint8List>{};

      final data = d.manufacturerData;
      if (data.isNotEmpty && data.length >= 2) {
        // Manufacturer data: [companyId(LE) , payload...]
        final companyId = data[0] | (data[1] << 8);
        final payload = Uint8List.fromList(data.sublist(2));
        md[companyId] = payload;
      }

      return BleAdvertisement(
        deviceId: d.id,
        localName: d.name.isEmpty ? null : d.name,
        manufacturerData: md,
      );
    });
  }

  @override
  Future<void> connect(String deviceId) async {
    final completer = Completer<void>();

    _connSub?.cancel();
    _connSub = _ble
        .connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds: 10),
    )
        .listen((update) {
      if (update.connectionState == DeviceConnectionState.connected && !completer.isCompleted) {
        completer.complete();
      } else if (update.connectionState == DeviceConnectionState.disconnected && !completer.isCompleted) {
        completer.completeError(
          Exception('Disconnected while connecting'),
        );
      }
    }, onError: (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  @override
  Future<int> requestMtu(String deviceId, int requested) async {
    try {
      final mtu = await _ble.requestMtu(deviceId: deviceId, mtu: requested);
      return mtu;
    } catch (_) {
      return 23;
    }
  }

  @override
  Stream<List<int>> subscribeToCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    final ch = QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(characteristicUuid),
    );

    return _ble.subscribeToCharacteristic(ch);
  }

  @override
  Future<void> writeToCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List value,
  }) {
    final ch = QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(characteristicUuid),
    );

    return _ble.writeCharacteristicWithResponse(ch, value: value);
  }

  @override
  Future<void> disconnect(String deviceId) async {
    await _connSub?.cancel();
    _connSub = null;
  }
}
