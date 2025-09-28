import 'package:flutter/widgets.dart';
import 'package:oshmobile/features/devices/unknown_device/presentation/pages/unknown_device_page.dart';

class DevicePageFactory {
  static Widget getPage(String type) {
    switch (type) {
      // case OshConfiguration.heaterType:
      //   return BlocProvider(
      //     create: (_) => ThermostatCubit(),
      //     child: ThermostatPage(),
      //   );
      default:
        return UnknownDevicePage();
    }
  }
}
