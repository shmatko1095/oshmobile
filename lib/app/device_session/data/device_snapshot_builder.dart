import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/configuration/control_registry.dart';
import 'package:oshmobile/core/configuration/control_state_resolver.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_page_cubit.dart';
import 'package:oshmobile/features/schedule/data/schedule_jsonrpc_codec.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema_builder.dart';

class DeviceSnapshotBuildResult {
  final DeviceSnapshot snapshot;
  final SettingsUiSchema? settingsUiSchema;

  const DeviceSnapshotBuildResult({
    required this.snapshot,
    required this.settingsUiSchema,
  });
}

class DeviceSnapshotBuilder {
  final Device _bootstrapDevice;
  final SettingsUiSchemaBuilder _settingsUiSchemaBuilder;
  final ControlStateResolver _controlStateResolver;
  final DeviceRuntimeContracts _runtimeContracts;

  const DeviceSnapshotBuilder({
    required Device bootstrapDevice,
    required SettingsUiSchemaBuilder settingsUiSchemaBuilder,
    required ControlStateResolver controlStateResolver,
    required DeviceRuntimeContracts runtimeContracts,
  })  : _bootstrapDevice = bootstrapDevice,
        _settingsUiSchemaBuilder = settingsUiSchemaBuilder,
        _controlStateResolver = controlStateResolver,
        _runtimeContracts = runtimeContracts;

  DeviceSnapshotBuildResult build({
    required DevicePageState pageState,
    required GlobalMqttState mqttState,
    required MqttCommState commState,
    required DeviceSlice<Map<String, dynamic>> telemetry,
    required TelemetryState? telemetryState,
    required DeviceSlice<CalendarSnapshot> schedule,
    required CalendarSnapshot? scheduleState,
    required DeviceSlice<SettingsSnapshot> settings,
    required SettingsSnapshot? settingsState,
    required SensorsState? sensorsState,
    required DeviceSlice<Map<String, dynamic>> about,
    required Map<String, dynamic>? aboutState,
  }) {
    var device = _bootstrapDevice;
    if (pageState is DevicePageReady) {
      device = pageState.device;
    }

    final details = _mapDetails(pageState);
    final settingsUiSchema = _buildSettingsUiSchema(pageState);

    final snapshot = DeviceSnapshot(
      device: device,
      details: details,
      mqttConnected: mqttState is MqttConnected,
      mqttBusy: commState.hasPending,
      commError: commState.lastError,
      telemetry: telemetry,
      controlState: _buildControlState(
        pageState,
        telemetryState: telemetryState,
        sensorsState: sensorsState,
        scheduleState: scheduleState,
        settingsState: settingsState,
        aboutState: aboutState,
      ),
      schedule: schedule,
      settings: settings,
      settingsUiSchema: settingsUiSchema,
      about: about,
      updatedAt: DateTime.now(),
    );

    return DeviceSnapshotBuildResult(
      snapshot: snapshot,
      settingsUiSchema: settingsUiSchema,
    );
  }

  SettingsUiSchema? _buildSettingsUiSchema(DevicePageState pageState) {
    if (pageState case DevicePageReady(:final bundle)) {
      try {
        return _settingsUiSchemaBuilder.build(bundle: bundle);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  DeviceSlice<Map<String, dynamic>> _buildControlState(
    DevicePageState pageState, {
    required TelemetryState? telemetryState,
    required SensorsState? sensorsState,
    required CalendarSnapshot? scheduleState,
    required SettingsSnapshot? settingsState,
    required Map<String, dynamic>? aboutState,
  }) {
    switch (pageState) {
      case DevicePageLoading():
        return const DeviceSlice<Map<String, dynamic>>.loading(data: {});
      case DevicePageError(:final message):
      case DevicePageUpdateRequired(:final message):
      case DevicePageCompatibilityError(:final message):
        return DeviceSlice<Map<String, dynamic>>.error(
          data: const <String, dynamic>{},
          error: message,
        );
      case DevicePageReady(:final bundle):
        final registry = ControlRegistry(bundle);
        final scheduleCodec = bundle.canReadDomain('schedule')
            ? ScheduleJsonRpcCodec.fromRuntimeContract(
                _runtimeContracts.schedule,
              )
            : null;
        final state = _controlStateResolver.resolveAll(
          registry: registry,
          controlIds: bundle.configuration.oshmobile.controls.keys,
          telemetry: telemetryState,
          sensors: sensorsState,
          schedule: scheduleState,
          scheduleCodec: scheduleCodec,
          settings: settingsState,
          deviceState: aboutState,
        );
        return DeviceSlice<Map<String, dynamic>>.ready(
          data: Map<String, dynamic>.unmodifiable(state),
        );
    }
  }

  DeviceSlice<DeviceConfigurationBundle> _mapDetails(DevicePageState state) {
    switch (state) {
      case DevicePageLoading():
        return const DeviceSlice<DeviceConfigurationBundle>.loading();
      case DevicePageError(:final message):
      case DevicePageUpdateRequired(:final message):
      case DevicePageCompatibilityError(:final message):
        return DeviceSlice<DeviceConfigurationBundle>.error(error: message);
      case DevicePageReady(:final bundle):
        return DeviceSlice<DeviceConfigurationBundle>.ready(data: bundle);
    }
  }
}
