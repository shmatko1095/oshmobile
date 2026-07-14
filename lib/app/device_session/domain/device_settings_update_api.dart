part of 'device_facade.dart';

abstract interface class DeviceSettingsUpdateApi {
  void setAutoUpdateEnabled(bool value);

  void setUpdateAtMidnight(bool value);

  void setCheckIntervalMin(int value);
}
