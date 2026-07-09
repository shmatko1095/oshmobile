import 'dart:async';

import 'package:oshmobile/app/device_session/data/apis/device_about_api_impl.dart';
import 'package:oshmobile/app/device_session/data/apis/device_schedule_api_impl.dart';
import 'package:oshmobile/app/device_session/data/apis/device_sensors_api_impl.dart';
import 'package:oshmobile/app/device_session/data/apis/device_settings_api_impl.dart';
import 'package:oshmobile/app/device_session/data/apis/device_telemetry_api_impl.dart';
import 'package:oshmobile/app/device_session/data/apis/device_telemetry_history_api_impl.dart';
import 'package:oshmobile/app/device_session/data/device_domain_api_coordinator.dart';
import 'package:oshmobile/app/device_session/data/device_snapshot_builder.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/configuration/control_state_resolver.dart';
import 'package:oshmobile/core/di/device_context.dart';
import 'package:oshmobile/core/logging/app_log.dart';
import 'package:oshmobile/features/device_about/domain/repositories/device_about_repository.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/telemetry_repository.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_page_cubit.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:oshmobile/features/settings/domain/repositories/settings_repository.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema_builder.dart';
import 'package:oshmobile/features/sensors/domain/repositories/sensors_repository.dart';
import 'package:oshmobile/features/telemetry_history/domain/usecases/get_telemetry_aggregate.dart';
import 'package:oshmobile/features/telemetry_history/domain/usecases/get_telemetry_history.dart';

class DeviceFacadeImpl implements DeviceFacade {
  final DeviceContext _ctx;
  final DevicePageCubit _pageCubit;
  final GlobalMqttCubit _mqttCubit;
  final MqttCommCubit _commCubit;
  final DeviceSnapshotBuilder _snapshotBuilder;

  late final DeviceScheduleApiImpl _scheduleApi;
  late final DeviceSettingsApiImpl _settingsApi;
  late final DeviceSensorsApiImpl _sensorsApi;
  late final DeviceTelemetryApiImpl _telemetryApi;
  late final DeviceTelemetryHistoryApiImpl _telemetryHistoryApi;
  late final DeviceAboutApiImpl _aboutApi;
  late final DeviceDomainApiCoordinator _domainApis;

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
  late final DeviceTelemetryHistoryApi telemetryHistory = _telemetryHistoryApi;

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
    required GetTelemetryHistory getTelemetryHistory,
    required GetTelemetryAggregate getTelemetryAggregate,
  })  : _ctx = ctx,
        _pageCubit = pageCubit,
        _mqttCubit = mqttCubit,
        _commCubit = commCubit,
        _snapshotBuilder = DeviceSnapshotBuilder(
          bootstrapDevice: bootstrapDevice,
          settingsUiSchemaBuilder: settingsUiSchemaBuilder,
          controlStateResolver: controlStateResolver,
        ),
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
    _telemetryHistoryApi = DeviceTelemetryHistoryApiImpl(
      deviceSn: _ctx.deviceSn,
      getTelemetryHistory: getTelemetryHistory,
      getTelemetryAggregate: getTelemetryAggregate,
    );
    _aboutApi = DeviceAboutApiImpl(
      repo: aboutRepo,
      onChanged: _publish,
    );
    _domainApis = DeviceDomainApiCoordinator(
      telemetryApi: _telemetryApi,
      scheduleApi: _scheduleApi,
      settingsApi: _settingsApi,
      sensorsApi: _sensorsApi,
      aboutApi: _aboutApi,
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

    _subs.add(_pageCubit.stream.listen((state) {
      if (state case DevicePageReady(:final bundle)) {
        unawaited(_domainApis.startSupportedApis(bundle));
      }
      _publish();
    }));
    _subs.add(_mqttCubit.stream.listen((_) => _publish()));
    _subs.add(_commCubit.stream.listen((_) => _publish()));

    if (_pageCubit.state case DevicePageReady(:final bundle)) {
      await _domainApis.startSupportedApis(bundle);
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
    await _pageCubit.load(_ctx.deviceSn);
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
      await _logAndIgnore(
        sub.cancel(),
        operation: 'cancel facade subscription',
      );
    }
    _subs.clear();

    await _domainApis.disposeApis();

    await _logAndIgnore(
      _snapshots.close(),
      operation: 'close snapshot stream',
    );
  }

  Future<void> _logAndIgnore(
    Future<void> future, {
    required String operation,
  }) {
    return future.catchError((Object error, StackTrace stackTrace) {
      AppLog.error(
        'DeviceFacade: $operation failed',
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  void _publish() {
    if (_disposed) return;

    _current = _buildSnapshot();
    if (!_snapshots.isClosed) {
      _snapshots.add(_current);
    }
  }

  Future<void> _refreshDomainSlices({required bool forceGet}) async {
    final pageState = _pageCubit.state;
    if (pageState is! DevicePageReady) {
      _publish();
      return;
    }

    final bundle = pageState.bundle;
    await _domainApis.refreshSupportedSlices(bundle, forceGet: forceGet);

    _publish();
  }

  DeviceSnapshot _buildSnapshot() {
    final result = _snapshotBuilder.build(
      pageState: _pageCubit.state,
      mqttState: _mqttCubit.state,
      commState: _commCubit.state,
      telemetry: _telemetryApi.slice,
      telemetryState: _telemetryApi.rawCurrent,
      schedule: _scheduleApi.slice,
      scheduleState: _scheduleApi.current,
      settings: _settingsApi.slice,
      settingsState: _settingsApi.current,
      sensorsState: _sensorsApi.current,
      about: _aboutApi.slice,
      aboutState: _aboutApi.current,
    );
    _settingsUiSchema = result.settingsUiSchema;
    return result.snapshot;
  }
}
