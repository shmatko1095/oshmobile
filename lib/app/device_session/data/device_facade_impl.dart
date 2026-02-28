import 'dart:async';

import 'package:oshmobile/app/device_session/data/apis/device_about_api_impl.dart';
import 'package:oshmobile/app/device_session/data/apis/device_schedule_api_impl.dart';
import 'package:oshmobile/app/device_session/data/apis/device_sensors_api_impl.dart';
import 'package:oshmobile/app/device_session/data/apis/device_settings_api_impl.dart';
import 'package:oshmobile/app/device_session/data/apis/device_telemetry_api_impl.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/di/device_context.dart';
import 'package:oshmobile/core/profile/control_binding_registry.dart';
import 'package:oshmobile/core/profile/control_state_resolver.dart';
import 'package:oshmobile/core/profile/models/device_profile_bundle.dart';
import 'package:oshmobile/features/device_about/domain/repositories/device_about_repository.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/telemetry_repository.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_page_cubit.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:oshmobile/features/settings/domain/repositories/settings_repository.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema_builder.dart';
import 'package:oshmobile/features/sensors/domain/repositories/sensors_repository.dart';

class DeviceFacadeImpl implements DeviceFacade {
  final DeviceContext _ctx;
  final Device _bootstrapDevice;
  final DevicePageCubit _pageCubit;
  final GlobalMqttCubit _mqttCubit;
  final MqttCommCubit _commCubit;
  final SettingsUiSchemaBuilder _settingsUiSchemaBuilder;
  final ControlStateResolver _controlStateResolver;

  late final DeviceScheduleApiImpl _scheduleApi;
  late final DeviceSettingsApiImpl _settingsApi;
  late final DeviceSensorsApiImpl _sensorsApi;
  late final DeviceTelemetryApiImpl _telemetryApi;
  late final DeviceAboutApiImpl _aboutApi;

  final StreamController<DeviceSnapshot> _snapshots =
      StreamController<DeviceSnapshot>.broadcast();
  final List<StreamSubscription<dynamic>> _subs =
      <StreamSubscription<dynamic>>[];

  bool _started = false;
  bool _disposed = false;

  @override
  late final DeviceScheduleApi schedule = _scheduleApi;

  @override
  late final DeviceSettingsApi settings = _settingsApi;

  @override
  late final DeviceSensorsApi sensors = _sensorsApi;

  @override
  late final DeviceTelemetryApi telemetry = _telemetryApi;

  @override
  late final DeviceAboutApi about = _aboutApi;

  DeviceSnapshot _current;
  SettingsUiSchema? _settingsUiSchema;

  DeviceFacadeImpl({
    required DeviceContext ctx,
    required Device bootstrapDevice,
    required DevicePageCubit pageCubit,
    required TelemetryRepository telemetryRepo,
    required ScheduleRepository scheduleRepo,
    required SettingsRepository settingsRepo,
    required DeviceAboutRepository aboutRepo,
    required GlobalMqttCubit mqttCubit,
    required MqttCommCubit commCubit,
    required SensorsRepository sensorsRepo,
    required SettingsUiSchemaBuilder settingsUiSchemaBuilder,
    required ControlStateResolver controlStateResolver,
  })  : _ctx = ctx,
        _bootstrapDevice = bootstrapDevice,
        _pageCubit = pageCubit,
        _mqttCubit = mqttCubit,
        _commCubit = commCubit,
        _settingsUiSchemaBuilder = settingsUiSchemaBuilder,
        _controlStateResolver = controlStateResolver,
        _current = DeviceSnapshot.initial(device: bootstrapDevice) {
    _scheduleApi = DeviceScheduleApiImpl(
      deviceSn: _ctx.deviceSn,
      repo: scheduleRepo,
      comm: _commCubit,
      onChanged: _publish,
    );
    _settingsApi = DeviceSettingsApiImpl(
      deviceSn: _ctx.deviceSn,
      repo: settingsRepo,
      comm: _commCubit,
      onChanged: _publish,
    );
    _sensorsApi = DeviceSensorsApiImpl(repo: sensorsRepo);
    _telemetryApi = DeviceTelemetryApiImpl(
      repo: telemetryRepo,
      onChanged: _publish,
    );
    _aboutApi = DeviceAboutApiImpl(
      repo: aboutRepo,
      onChanged: _publish,
    );
  }

  @override
  DeviceSnapshot get current => _current;

  @override
  SettingsUiSchema? get settingsUiSchema => _settingsUiSchema;

  @override
  Future<void> start() async {
    if (_disposed || _started) return;
    _started = true;

    _subs.add(_pageCubit.stream.listen((_) => _publish()));
    _subs.add(_mqttCubit.stream.listen((_) => _publish()));
    _subs.add(_commCubit.stream.listen((_) => _publish()));

    await Future.wait<void>([
      _telemetryApi.start().catchError((_) {}),
      _scheduleApi.start().catchError((_) {}),
      _settingsApi.start().catchError((_) {}),
      _aboutApi.start().catchError((_) {}),
      _sensorsApi.start().catchError((_) {}),
    ]);

    if (_pageCubit.state is DevicePageReady) {
      await _refreshDomainSlices(forceGet: false);
    } else {
      _publish();
    }
  }

  @override
  Stream<DeviceSnapshot> watch() {
    if (_disposed) {
      return Stream<DeviceSnapshot>.value(_current);
    }
    if (!_started) {
      unawaited(start());
    }

    return Stream<DeviceSnapshot>.multi((controller) {
      controller.add(_current);
      final sub = _snapshots.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<void> refreshAll({bool forceGet = false}) async {
    await _pageCubit.load(_ctx.deviceId);
    if (_pageCubit.state is! DevicePageReady) {
      _publish();
      return;
    }

    await _refreshDomainSlices(forceGet: forceGet);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    for (final sub in _subs) {
      try {
        await sub.cancel();
      } catch (_) {}
    }
    _subs.clear();

    await Future.wait<void>([
      _telemetryApi.dispose().catchError((_) {}),
      _scheduleApi.dispose().catchError((_) {}),
      _settingsApi.dispose().catchError((_) {}),
      _aboutApi.dispose().catchError((_) {}),
      _sensorsApi.dispose().catchError((_) {}),
    ]);

    try {
      await _snapshots.close();
    } catch (_) {}
  }

  void _publish() {
    if (_disposed) return;

    _current = _buildSnapshot();
    if (!_snapshots.isClosed) {
      _snapshots.add(_current);
    }
  }

  Future<void> _refreshDomainSlices({required bool forceGet}) async {
    await Future.wait<void>([
      _telemetryApi.get(force: forceGet).then((_) {}).catchError((_) {}),
      _scheduleApi.get(force: forceGet).then((_) {}).catchError((_) {}),
      _settingsApi.get(force: forceGet).then((_) {}).catchError((_) {}),
      _sensorsApi.get(force: forceGet).then((_) {}).catchError((_) {}),
      _aboutApi.get(force: forceGet).then((_) {}).catchError((_) {}),
    ]);

    _publish();
  }

  DeviceSnapshot _buildSnapshot() {
    final pageState = _pageCubit.state;
    final mqttState = _mqttCubit.state;
    final commState = _commCubit.state;

    var device = _bootstrapDevice;
    if (pageState is DevicePageReady) {
      device = pageState.device;
    }

    final details = _mapDetails(pageState);
    final settingsUiSchema = _buildSettingsUiSchema(pageState);
    _settingsUiSchema = settingsUiSchema;

    return DeviceSnapshot(
      device: device,
      details: details,
      mqttConnected: mqttState is MqttConnected,
      mqttBusy: commState.hasPending,
      commError: commState.lastError,
      telemetry: _telemetryApi.slice,
      controlState: _buildControlState(pageState),
      schedule: _scheduleApi.slice,
      settings: _settingsApi.slice,
      settingsUiSchema: settingsUiSchema,
      about: _aboutApi.slice,
      updatedAt: DateTime.now(),
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
      DevicePageState pageState) {
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
        final registry = ControlBindingRegistry(bundle);
        final state = _controlStateResolver.resolveAll(
          registry: registry,
          controlIds: bundle.bindings.keys,
          telemetry: _telemetryApi.rawCurrent,
          sensors: _sensorsApi.current,
          schedule: _scheduleApi.current,
          settings: _settingsApi.current,
          deviceState: _aboutApi.current,
        );
        return DeviceSlice<Map<String, dynamic>>.ready(
          data: Map<String, dynamic>.unmodifiable(state),
        );
    }
  }

  DeviceSlice<DeviceProfileBundle> _mapDetails(DevicePageState state) {
    switch (state) {
      case DevicePageLoading():
        return const DeviceSlice<DeviceProfileBundle>.loading();
      case DevicePageError(:final message):
      case DevicePageUpdateRequired(:final message):
      case DevicePageCompatibilityError(:final message):
        return DeviceSlice<DeviceProfileBundle>.error(error: message);
      case DevicePageReady(:final bundle):
        return DeviceSlice<DeviceProfileBundle>.ready(data: bundle);
    }
  }
}
