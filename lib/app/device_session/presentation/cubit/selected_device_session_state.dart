part of 'selected_device_session_cubit.dart';

class SelectedDeviceSessionState {
  final String? deviceId;
  final bool canOpenInternalSettings;
  final bool canOpenAbout;

  const SelectedDeviceSessionState({
    this.deviceId,
    this.canOpenInternalSettings = false,
    this.canOpenAbout = false,
  });

  SelectedDeviceSessionState copyWith({
    String? deviceId,
    bool? canOpenInternalSettings,
    bool? canOpenAbout,
  }) {
    return SelectedDeviceSessionState(
      deviceId: deviceId ?? this.deviceId,
      canOpenInternalSettings:
          canOpenInternalSettings ?? this.canOpenInternalSettings,
      canOpenAbout: canOpenAbout ?? this.canOpenAbout,
    );
  }
}
