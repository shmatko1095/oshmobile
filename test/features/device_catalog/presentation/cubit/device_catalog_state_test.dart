import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/device_catalog/presentation/cubit/device_catalog_cubit.dart';

void main() {
  test('copyWith keeps selectedDeviceId when not overridden', () {
    const state = DeviceCatalogState(selectedDeviceId: 'device-1');

    final next = state.copyWith(status: DeviceCatalogStatus.ready);

    expect(next.selectedDeviceId, 'device-1');
  });

  test('copyWith can clear selectedDeviceId explicitly', () {
    const state = DeviceCatalogState(selectedDeviceId: 'device-1');

    final next = state.copyWith(selectedDeviceId: null);

    expect(next.selectedDeviceId, isNull);
  });
}
