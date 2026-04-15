import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/features/device_about/presentation/open_device_about_page.dart';
import 'package:oshmobile/features/settings/presentation/open_settings_page.dart';

part 'selected_device_session_state.dart';

class SelectedDeviceSessionCubit extends Cubit<SelectedDeviceSessionState> {
  SelectedDeviceSessionCubit() : super(const SelectedDeviceSessionState());

  DeviceFacade? _facade;
  DeviceSnapshotCubit? _snapshotCubit;

  void bind({
    required String deviceId,
    required DeviceFacade facade,
    required DeviceSnapshotCubit snapshotCubit,
  }) {
    _facade = facade;
    _snapshotCubit = snapshotCubit;
    emit(
      state.copyWith(
        deviceId: deviceId,
        canOpenAbout: false,
        canOpenInternalSettings: false,
      ),
    );
  }

  void updateAvailability({
    required String deviceId,
    required bool canOpenInternalSettings,
    required bool canOpenAbout,
  }) {
    if (state.deviceId != deviceId) return;

    emit(
      state.copyWith(
        canOpenInternalSettings: canOpenInternalSettings,
        canOpenAbout: canOpenAbout,
      ),
    );
  }

  void clear(String deviceId) {
    if (state.deviceId != deviceId) return;

    _facade = null;
    _snapshotCubit = null;
    emit(const SelectedDeviceSessionState());
  }

  void openInternalSettings(BuildContext context, Device device) {
    final facade = _facade;
    final snapshotCubit = _snapshotCubit;
    if (!state.canOpenInternalSettings ||
        facade == null ||
        snapshotCubit == null ||
        state.deviceId != device.id) {
      OshCrashReporter.log(
        'SelectedDeviceSessionCubit: skipped internal settings open '
        'device=${device.id} canOpen=${state.canOpenInternalSettings} '
        'hasFacade=${facade != null} hasSnapshot=${snapshotCubit != null} '
        'sessionDevice=${state.deviceId ?? '-'}',
      );
      return;
    }

    DeviceSettingsNavigator.openInternal(
      context,
      device: device,
      facade: facade,
      snapshotCubit: snapshotCubit,
    );
  }

  void openAbout(BuildContext context, Device device) {
    final facade = _facade;
    final snapshotCubit = _snapshotCubit;
    if (!state.canOpenAbout ||
        facade == null ||
        snapshotCubit == null ||
        state.deviceId != device.id) {
      OshCrashReporter.log(
        'SelectedDeviceSessionCubit: skipped about open '
        'device=${device.id} canOpen=${state.canOpenAbout} '
        'hasFacade=${facade != null} hasSnapshot=${snapshotCubit != null} '
        'sessionDevice=${state.deviceId ?? '-'}',
      );
      return;
    }

    DeviceAboutNavigator.openFromSession(
      context,
      device: device,
      facade: facade,
      snapshotCubit: snapshotCubit,
    );
  }
}
