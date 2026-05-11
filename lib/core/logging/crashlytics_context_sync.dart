import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart';
import 'package:oshmobile/core/common/entities/device/known_device_models.dart';
import 'package:oshmobile/core/logging/crashlytics_context_keys.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/cubit/ble_provisioning_cubit.dart';
import 'package:oshmobile/features/device_catalog/presentation/cubit/device_catalog_cubit.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_status.dart';
import 'package:oshmobile/features/startup/presentation/cubit/startup_state.dart';

final class CrashlyticsContextSync {
  CrashlyticsContextSync._();

  static Future<void> syncSessionAuthContext({
    required bool isDemoMode,
    required String? authProvider,
  }) {
    final normalizedProvider = _normalizeAuthProvider(authProvider, isDemoMode);
    return OshCrashReporter.setContext({
      CrashlyticsContextKeys.sessionMode: isDemoMode
          ? CrashlyticsContextValues.demo
          : CrashlyticsContextValues.real,
      CrashlyticsContextKeys.authProvider: normalizedProvider,
    });
  }

  static Future<void> syncStartupState(StartupState state) {
    return OshCrashReporter.setContext({
      CrashlyticsContextKeys.startupPhase: _startupPhaseValue(state),
      CrashlyticsContextKeys.policyStatus:
          _policyStatusValue(state.policyStatus),
    });
  }

  static Future<void> syncMqttState(GlobalMqttState state) {
    return OshCrashReporter.setContext({
      CrashlyticsContextKeys.mqttConnected: state is MqttConnected,
    });
  }

  static Future<void> syncDeviceCatalogState(DeviceCatalogState state) {
    return OshCrashReporter.setContext({
      CrashlyticsContextKeys.selectedDeviceType: _selectedDeviceType(state),
    });
  }

  static Future<void> syncBleState(BleProvisioningState state) {
    return OshCrashReporter.setContext({
      CrashlyticsContextKeys.bleFlowStep:
          _enumNameToSnakeCase(state.status.name),
    });
  }

  static String _normalizeAuthProvider(String? authProvider, bool isDemoMode) {
    final normalized = authProvider?.trim().toLowerCase();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
    return isDemoMode
        ? CrashlyticsContextValues.demo
        : CrashlyticsContextValues.none;
  }

  static String _startupPhaseValue(StartupState state) {
    return switch (state.stage) {
      StartupStage.checkingConnectivity => 'checking_connectivity',
      StartupStage.restoringSession => 'restoring_session',
      StartupStage.noInternet => 'no_internet',
      StartupStage.ready => 'ready',
    };
  }

  static String _policyStatusValue(MobileClientPolicyStatus? status) {
    return status?.wireValue ?? CrashlyticsContextValues.none;
  }

  static String _selectedDeviceType(DeviceCatalogState state) {
    final selectedDeviceId = state.selectedDeviceId;
    if (selectedDeviceId == null || selectedDeviceId.isEmpty) {
      return CrashlyticsContextValues.none;
    }

    for (final device in state.devices) {
      if (device.id != selectedDeviceId) continue;
      return _normalizeDeviceFamily(device.modelId, device.modelName);
    }

    return CrashlyticsContextValues.none;
  }

  static String _normalizeDeviceFamily(String modelId, String modelName) {
    final normalizedModelId = modelId.trim().toLowerCase();
    if (normalizedModelId == t1aFlWzeModelId.toLowerCase()) {
      return 'thermostat';
    }

    final fingerprint = '$normalizedModelId ${modelName.trim().toLowerCase()}';
    if (fingerprint.contains('thermostat') || fingerprint.contains('t1a')) {
      return 'thermostat';
    }
    if (fingerprint.contains('hub')) {
      return 'hub';
    }
    if (fingerprint.contains('sensor')) {
      return 'sensor';
    }
    return CrashlyticsContextValues.unknown;
  }

  static String _enumNameToSnakeCase(String value) {
    return value
        .replaceAllMapped(
          RegExp('([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .toLowerCase();
  }
}
