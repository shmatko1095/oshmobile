part of 'device_facade.dart';

abstract interface class DeviceSettingsDisplayApi {
  void setActiveBrightness(int value);

  void setIdleBrightness(int value);

  void setIdleTime(int value);

  void setDimOnIdle(bool value);

  void setLanguage(String value);
}
