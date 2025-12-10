part of 'device_settings_cubit.dart';

sealed class DeviceSettingsState {
  const DeviceSettingsState();
}

final class DeviceSettingsLoading extends DeviceSettingsState {
  const DeviceSettingsLoading();
}

final class DeviceSettingsError extends DeviceSettingsState {
  final String message;

  const DeviceSettingsError(this.message);
}

final class DeviceSettingsReady extends DeviceSettingsState {
  /// Confirmed or last-known snapshot from device, WITH local edits applied.
  final SettingsSnapshot snapshot;

  /// Whether there are local unsaved changes.
  final bool dirty;

  /// Whether we are currently waiting for device ACK.
  final bool saving;

  /// Optional last one-shot message for UI (SnackBar / banner).
  final String? flash;

  /// ReqId for in-flight save operation, if any.
  final String? pendingReqId;

  const DeviceSettingsReady({
    required this.snapshot,
    this.dirty = false,
    this.saving = false,
    this.flash,
    this.pendingReqId,
  });

  DeviceSettingsReady copyWith({
    SettingsSnapshot? snapshot,
    bool? dirty,
    bool? saving,
    String? flash, // pass null to clear
    String? pendingReqId,
  }) {
    return DeviceSettingsReady(
      snapshot: snapshot ?? this.snapshot,
      dirty: dirty ?? this.dirty,
      saving: saving ?? this.saving,
      flash: flash,
      pendingReqId: pendingReqId,
    );
  }
}
