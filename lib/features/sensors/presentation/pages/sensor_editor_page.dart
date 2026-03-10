import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/scopes/device_route_scope.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/sensors/presentation/models/sensor_editor_entry.dart';
import 'package:oshmobile/features/sensors/presentation/pages/sensor_calibration_page.dart';
import 'package:oshmobile/features/sensors/presentation/pages/sensor_rename_page.dart';
import 'package:oshmobile/generated/l10n.dart';

class SensorEditorPage extends StatefulWidget {
  final SensorEditorEntry sensor;

  const SensorEditorPage({
    super.key,
    required this.sensor,
  });

  @override
  State<SensorEditorPage> createState() => _SensorEditorPageState();
}

class _SensorEditorPageState extends State<SensorEditorPage> {
  bool _isSettingReference = false;

  SensorMeta? _findSensor(SensorsState? state) {
    if (state == null) return null;
    for (final sensor in state.items) {
      if (sensor.id == widget.sensor.id) {
        return sensor;
      }
    }
    return null;
  }

  _TelemetryData? _findTelemetry(Map<String, dynamic>? telemetryData) {
    if (telemetryData == null) return null;
    final list = telemetryData['climate_sensors'];
    if (list is! List) return null;

    for (final raw in list) {
      if (raw is! Map) continue;
      final map = raw.cast<String, dynamic>();
      final id = map['id']?.toString();
      if (id != widget.sensor.id) continue;

      final tempValid = _asBool(map['temp_valid']);
      final humidityValid = _asBool(map['humidity_valid']);
      final temp = _asNum(map['temp'])?.toDouble();
      final humidity = _asNum(map['humidity'])?.toDouble();

      return _TelemetryData(
        tempValid: tempValid && temp != null,
        humidityValid: humidityValid && humidity != null,
        temp: temp,
        humidity: humidity,
      );
    }

    return null;
  }

  num? _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == '1';
    }
    return false;
  }

  String _displayName(SensorMeta? sensor) {
    final source = sensor?.name ?? widget.sensor.name;
    final normalized = source.trim();
    if (normalized.isNotEmpty) return normalized;
    return widget.sensor.id;
  }

  String _fmtTemperature(num? value) {
    if (value == null) return '--';
    final v = value.toDouble();
    if (v.isNaN || v.isInfinite) return '--';
    return v.toStringAsFixed(1);
  }

  String _fmtHumidity(num? value) {
    if (value == null) return '--';
    final v = value.toDouble();
    if (v.isNaN || v.isInfinite) return '--';
    return v.toStringAsFixed(0);
  }

  String _fmtCalibration(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  String _calibrationSubtitle(SensorMeta? sensor) {
    if (sensor == null) return '--';
    return '${_fmtCalibration(sensor.tempCalibration)} °C';
  }

  Future<void> _setReference(SensorMeta? sensor) async {
    if (_isSettingReference || sensor == null || sensor.ref) return;

    setState(() => _isSettingReference = true);

    try {
      final facade = context.read<DeviceFacade>();
      await facade.sensors.setReference(id: sensor.id);
      await facade.refreshAll(forceGet: true);
      if (mounted) {
        SnackBarUtils.showSuccess(
          context: context,
          content: S.of(context).Done,
        );
      }
    } catch (error) {
      if (mounted) {
        SnackBarUtils.showFail(
          context: context,
          content: error.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSettingReference = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final facade = context.read<DeviceFacade>();

    return StreamBuilder<SensorsState>(
      stream: facade.sensors.watch(),
      initialData: facade.sensors.current,
      builder: (context, sensorsSnapshot) {
        final sensor = _findSensor(sensorsSnapshot.data);
        final title = _displayName(sensor);

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              title,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: BlocBuilder<DeviceSnapshotCubit, DeviceSnapshot>(
            buildWhen: (previous, current) {
              return previous.telemetry != current.telemetry ||
                  previous.details != current.details;
            },
            builder: (context, snapshot) {
              final telemetry = _findTelemetry(snapshot.telemetry.data);

              final tempValid = telemetry?.tempValid ?? widget.sensor.tempValid;
              final humidityValid =
                  telemetry?.humidityValid ?? widget.sensor.humidityValid;
              final temp = telemetry?.temp ?? widget.sensor.temp;
              final humidity = telemetry?.humidity ?? widget.sensor.humidity;

              return RefreshIndicator(
                onRefresh: () => facade.refreshAll(forceGet: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    AppSolidCard(
                      radius: AppPalette.radiusXl,
                      backgroundColor: AppPalette.surfaceRaised,
                      borderColor:
                          AppPalette.accentPrimary.withValues(alpha: 0.26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.of(context).SensorConditions,
                            style: const TextStyle(
                              color: AppPalette.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                tempValid ? _fmtTemperature(temp) : '--',
                                style: const TextStyle(
                                  color: AppPalette.textPrimary,
                                  fontSize: 68,
                                  fontWeight: FontWeight.w300,
                                  height: 0.95,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 11),
                                child: Text(
                                  '°C',
                                  style: TextStyle(
                                    color: AppPalette.textSecondary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.water_drop_rounded,
                                    size: 18,
                                    color: AppPalette.accentPrimary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    humidityValid
                                        ? '${_fmtHumidity(humidity)}%'
                                        : '--',
                                    style: const TextStyle(
                                      color: AppPalette.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (!tempValid || !humidityValid) ...[
                            const SizedBox(height: 10),
                            Text(
                              S.of(context).NoDataYet,
                              style: const TextStyle(
                                color: AppPalette.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppPalette.radiusXl),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(S.of(context).Name),
                            subtitle: Text(title),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: sensor == null
                                ? null
                                : () {
                                    final facade = context.read<DeviceFacade>();
                                    final snapshotCubit =
                                        context.read<DeviceSnapshotCubit>();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DeviceRouteScope.provide(
                                          facade: facade,
                                          snapshotCubit: snapshotCubit,
                                          child: SensorRenamePage(
                                            sensorId: sensor.id,
                                            initialName: title,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: Text(S.of(context).SensorCalibration),
                            subtitle: Text(_calibrationSubtitle(sensor)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: sensor == null
                                ? null
                                : () async {
                                    final facade = context.read<DeviceFacade>();
                                    final snapshotCubit =
                                        context.read<DeviceSnapshotCubit>();
                                    final saved =
                                        await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DeviceRouteScope.provide(
                                          facade: facade,
                                          snapshotCubit: snapshotCubit,
                                          child: SensorCalibrationPage(
                                            sensorId: sensor.id,
                                            initialCalibration:
                                                sensor.tempCalibration,
                                          ),
                                        ),
                                      ),
                                    );
                                    if (!mounted || saved != true) return;
                                    SnackBarUtils.showSuccess(
                                      context: this.context,
                                      content: S.of(this.context).Done,
                                    );
                                  },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: S.of(context).SensorMakeMain,
                      onPressed:
                          (sensor == null || sensor.ref || _isSettingReference)
                              ? null
                              : () => _setReference(sensor),
                      isLoading: _isSettingReference,
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      text: S.of(context).DeleteSensor,
                      onPressed: null,
                      backgroundColor: AppPalette.destructiveBg,
                      foregroundColor: AppPalette.destructiveFg,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _TelemetryData {
  final bool tempValid;
  final bool humidityValid;
  final double? temp;
  final double? humidity;

  const _TelemetryData({
    required this.tempValid,
    required this.humidityValid,
    required this.temp,
    required this.humidity,
  });
}
