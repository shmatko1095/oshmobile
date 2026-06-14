import 'package:oshmobile/core/configuration/control_registry.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/configuration/power_meter_series_keys.dart';
import 'package:oshmobile/features/devices/details/domain/builders/thermostat_dashboard_schema_builder.dart';
import 'package:oshmobile/features/devices/details/domain/models/thermostat_dashboard_schema.dart';

class ConfigurationThermostatDashboardSchemaBuilder
    implements ThermostatDashboardSchemaBuilder {
  const ConfigurationThermostatDashboardSchemaBuilder();

  @override
  ThermostatDashboardSchema build({required DeviceConfigurationBundle bundle}) {
    final registry = ControlRegistry(bundle);
    final visibleWidgetIds = <String>[];

    final hero = _buildHeroSpec(bundle, registry);
    if (hero != null) {
      visibleWidgetIds.add(_heroWidgetId);
    }

    final modeBar = _buildModeBarSpec(bundle, registry);
    if (modeBar != null) {
      visibleWidgetIds.add(_modeBarWidgetId);
    }

    final temperatureHistoryStrip = hero == null || hero.sensorsBind.isEmpty
        ? null
        : ThermostatTemperatureHistoryStripSpec(
            sensorsBind: hero.sensorsBind,
          );

    final climateSensorPairing =
        _buildClimateSensorPairingSpec(bundle, registry);
    if (climateSensorPairing != null) {
      visibleWidgetIds.add(_climateSensorPairingWidgetId);
    }

    final energySeriesKeys = _energySeriesKeys(bundle, registry);
    final electricalSeriesKeys = _electricalSeriesKeys(bundle, registry);

    final tiles = <ThermostatTileSpec>[];
    for (final descriptor in _tileDescriptors) {
      if (!_canRenderWidget(bundle, registry, descriptor.widgetId)) {
        continue;
      }
      final tile = _buildTileSpec(
        bundle: bundle,
        registry: registry,
        descriptor: descriptor,
        energySeriesKeys: energySeriesKeys,
        electricalSeriesKeys: electricalSeriesKeys,
      );
      if (tile == null) {
        continue;
      }
      tiles.add(tile);
      visibleWidgetIds.add(descriptor.widgetId);
    }

    return ThermostatDashboardSchema(
      hero: hero,
      modeBar: modeBar,
      temperatureHistoryStrip: temperatureHistoryStrip,
      climateSensorPairing: climateSensorPairing,
      tiles: List<ThermostatTileSpec>.unmodifiable(tiles),
      visibleWidgetIds: List<String>.unmodifiable(visibleWidgetIds),
    );
  }

  ThermostatHeroSpec? _buildHeroSpec(
    DeviceConfigurationBundle bundle,
    ControlRegistry registry,
  ) {
    if (!_canRenderWidget(bundle, registry, _heroWidgetId)) {
      return null;
    }

    final currentBind = _requiredWidgetBind(bundle, registry, _heroWidgetId, 0);
    final currentTargetBind =
        _requiredWidgetBind(bundle, registry, _heroWidgetId, 1);
    final nextTargetBind =
        _requiredWidgetBind(bundle, registry, _heroWidgetId, 2);
    final sensorsBind = _requiredWidgetBind(bundle, registry, _heroWidgetId, 3);

    if (currentBind == null ||
        currentTargetBind == null ||
        nextTargetBind == null ||
        sensorsBind == null) {
      return null;
    }

    return ThermostatHeroSpec(
      currentBind: currentBind,
      currentTargetBind: currentTargetBind,
      nextTargetBind: nextTargetBind,
      sensorsBind: sensorsBind,
    );
  }

  ThermostatModeBarSpec? _buildModeBarSpec(
    DeviceConfigurationBundle bundle,
    ControlRegistry registry,
  ) {
    if (!_canRenderWidget(bundle, registry, _modeBarWidgetId)) {
      return null;
    }

    final modeBind = _requiredWidgetBind(bundle, registry, _modeBarWidgetId, 0);
    if (modeBind == null) {
      return null;
    }

    return ThermostatModeBarSpec(
      modeBind: modeBind,
      visibleModeIds: _visibleModeIds(bundle),
    );
  }

  ClimateSensorPairingSpec? _buildClimateSensorPairingSpec(
    DeviceConfigurationBundle bundle,
    ControlRegistry registry,
  ) {
    if (!_canRenderWidget(bundle, registry, _climateSensorPairingWidgetId) ||
        !bundle.canPatchDomain('sensors')) {
      return null;
    }

    final widget = bundle.widget(_climateSensorPairingWidgetId);
    if (widget == null) return null;

    final rawTransport = widget.options['transport']?.toString().trim();
    final transport =
        rawTransport == null || rawTransport.isEmpty ? 'zigbee' : rawTransport;
    if (transport.toLowerCase() != 'zigbee') {
      return null;
    }

    return ClimateSensorPairingSpec(
      transport: transport,
      timeoutSec: _positiveIntOption(widget.options['timeout_sec']) ?? 180,
    );
  }

  ThermostatTileSpec? _buildTileSpec({
    required DeviceConfigurationBundle bundle,
    required ControlRegistry registry,
    required _TileDescriptor descriptor,
    required List<String> energySeriesKeys,
    required List<String> electricalSeriesKeys,
  }) {
    final historyIntent = _buildHistoryIntent(
      descriptor: descriptor,
      energySeriesKeys: energySeriesKeys,
      electricalSeriesKeys: electricalSeriesKeys,
    );

    switch (descriptor.shape) {
      case _TileShape.singleBind:
        final bind =
            _requiredWidgetBind(bundle, registry, descriptor.widgetId, 0);
        if (bind == null) {
          return null;
        }
        return ThermostatSingleBindTileSpec(
          type: descriptor.type,
          bind: bind,
          telemetryHistoryIntent: historyIntent,
        );
      case _TileShape.valueWithOptionalValid:
        final valueBind =
            _requiredWidgetBind(bundle, registry, descriptor.widgetId, 0);
        if (valueBind == null) {
          return null;
        }
        return ThermostatValueTileSpec(
          type: descriptor.type,
          valueBind: valueBind,
          validBind: _optionalWidgetBind(
            bundle,
            registry,
            descriptor.widgetId,
            1,
          ),
          telemetryHistoryIntent: historyIntent,
        );
      case _TileShape.delta:
        final inletBind =
            _requiredWidgetBind(bundle, registry, descriptor.widgetId, 0);
        final outletBind =
            _requiredWidgetBind(bundle, registry, descriptor.widgetId, 1);
        if (inletBind == null || outletBind == null) {
          return null;
        }
        return ThermostatDeltaTileSpec(
          inletBind: inletBind,
          outletBind: outletBind,
        );
    }
  }

  TelemetryHistoryIntent? _buildHistoryIntent({
    required _TileDescriptor descriptor,
    required List<String> energySeriesKeys,
    required List<String> electricalSeriesKeys,
  }) {
    if (descriptor.historyGroup == null ||
        descriptor.initialSeriesKey == null) {
      return null;
    }

    final configuredSeriesKeys = switch (descriptor.historyGroup!) {
      TelemetryHistoryIntentGroup.energy => energySeriesKeys,
      TelemetryHistoryIntentGroup.electrical => electricalSeriesKeys,
      TelemetryHistoryIntentGroup.powerConsumption => <String>[
          ...energySeriesKeys,
          ...electricalSeriesKeys,
        ],
    };

    if (configuredSeriesKeys.isEmpty) {
      return null;
    }

    return TelemetryHistoryIntent(
      group: descriptor.historyGroup!,
      initialSeriesKey: descriptor.initialSeriesKey!,
      configuredSeriesKeys: List<String>.unmodifiable(configuredSeriesKeys),
    );
  }

  List<String>? _visibleModeIds(DeviceConfigurationBundle bundle) {
    final ids = bundle.widget(_modeBarWidgetId)?.modes ?? const <String>[];
    if (ids.isEmpty) {
      return null;
    }

    return ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  int? _positiveIntOption(Object? raw) {
    if (raw is int && raw > 0) return raw;
    if (raw is num && raw > 0) return raw.toInt();
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  List<String> _energySeriesKeys(
    DeviceConfigurationBundle bundle,
    ControlRegistry registry,
  ) {
    if (!_canRenderWidget(bundle, registry, _energyWidgetId) &&
        !_canRenderWidget(bundle, registry, _powerWidgetId)) {
      return const <String>[];
    }

    final energyBind =
        _requiredWidgetBind(bundle, registry, _energyWidgetId, 0);
    final powerBind = _requiredWidgetBind(bundle, registry, _powerWidgetId, 0);
    if (energyBind == null && powerBind == null) {
      return const <String>[];
    }

    return const <String>[
      PowerMeterSeriesKeys.energyWhDelta,
    ];
  }

  List<String> _electricalSeriesKeys(
    DeviceConfigurationBundle bundle,
    ControlRegistry registry,
  ) {
    final keys = <String>[];

    for (final descriptor in _tileDescriptors) {
      if ((descriptor.historyGroup != TelemetryHistoryIntentGroup.electrical &&
              descriptor.historyGroup !=
                  TelemetryHistoryIntentGroup.powerConsumption) ||
          descriptor.seriesKey == null) {
        continue;
      }

      if (!_canRenderWidget(bundle, registry, descriptor.widgetId)) {
        continue;
      }

      final valueBind =
          _requiredWidgetBind(bundle, registry, descriptor.widgetId, 0);
      if (valueBind == null) {
        continue;
      }

      keys.add(descriptor.seriesKey!);
    }

    return keys;
  }

  bool _canRenderWidget(
    DeviceConfigurationBundle bundle,
    ControlRegistry registry,
    String widgetId,
  ) {
    final widget = bundle.widget(widgetId);
    if (widget == null || widget.controlIds.isEmpty) {
      return false;
    }
    return widget.controlIds.every(registry.canRead);
  }

  String? _requiredWidgetBind(
    DeviceConfigurationBundle bundle,
    ControlRegistry registry,
    String widgetId,
    int index,
  ) {
    final widget = bundle.widget(widgetId);
    if (widget == null || index >= widget.controlIds.length) {
      return null;
    }

    final bind = widget.controlIds[index].trim();
    if (bind.isEmpty || !registry.canRead(bind)) {
      return null;
    }

    return bind;
  }

  String? _optionalWidgetBind(
    DeviceConfigurationBundle bundle,
    ControlRegistry registry,
    String widgetId,
    int index,
  ) {
    final widget = bundle.widget(widgetId);
    if (widget == null || index >= widget.controlIds.length) {
      return null;
    }

    final bind = widget.controlIds[index].trim();
    if (bind.isEmpty || !registry.canRead(bind)) {
      return null;
    }

    return bind;
  }
}

const String _heroWidgetId = 'heroTemperature';
const String _modeBarWidgetId = 'modeBar';
const String _climateSensorPairingWidgetId = 'climateSensorPairing';
const String _energyWidgetId = 'energyUsed';
const String _powerWidgetId = 'powerNow';

enum _TileShape {
  singleBind,
  valueWithOptionalValid,
  delta,
}

class _TileDescriptor {
  const _TileDescriptor({
    required this.widgetId,
    required this.type,
    required this.shape,
    this.historyGroup,
    this.initialSeriesKey,
    this.seriesKey,
  });

  final String widgetId;
  final ThermostatTileType type;
  final _TileShape shape;
  final TelemetryHistoryIntentGroup? historyGroup;
  final String? initialSeriesKey;
  final String? seriesKey;
}

const List<_TileDescriptor> _tileDescriptors = <_TileDescriptor>[
  _TileDescriptor(
    widgetId: 'heatingToggle',
    type: ThermostatTileType.heatingToggle,
    shape: _TileShape.singleBind,
  ),
  _TileDescriptor(
    widgetId: 'loadFactor24h',
    type: ThermostatTileType.loadFactor24h,
    shape: _TileShape.singleBind,
  ),
  _TileDescriptor(
    widgetId: 'energyUsed',
    type: ThermostatTileType.energyUsed,
    shape: _TileShape.valueWithOptionalValid,
    historyGroup: TelemetryHistoryIntentGroup.energy,
    initialSeriesKey: PowerMeterSeriesKeys.energyWhDelta,
    seriesKey: PowerMeterSeriesKeys.energyWhDelta,
  ),
  _TileDescriptor(
    widgetId: 'powerNow',
    type: ThermostatTileType.powerNow,
    shape: _TileShape.valueWithOptionalValid,
    historyGroup: TelemetryHistoryIntentGroup.powerConsumption,
    initialSeriesKey: PowerMeterSeriesKeys.energyWhDelta,
    seriesKey: PowerMeterSeriesKeys.activePowerW,
  ),
  _TileDescriptor(
    widgetId: 'voltageNow',
    type: ThermostatTileType.voltageNow,
    shape: _TileShape.valueWithOptionalValid,
    historyGroup: TelemetryHistoryIntentGroup.electrical,
    initialSeriesKey: PowerMeterSeriesKeys.voltageV,
    seriesKey: PowerMeterSeriesKeys.voltageV,
  ),
  _TileDescriptor(
    widgetId: 'currentNow',
    type: ThermostatTileType.currentNow,
    shape: _TileShape.valueWithOptionalValid,
    historyGroup: TelemetryHistoryIntentGroup.electrical,
    initialSeriesKey: PowerMeterSeriesKeys.currentA,
    seriesKey: PowerMeterSeriesKeys.currentA,
  ),
  _TileDescriptor(
    widgetId: 'apparentPowerNow',
    type: ThermostatTileType.apparentPowerNow,
    shape: _TileShape.valueWithOptionalValid,
    historyGroup: TelemetryHistoryIntentGroup.electrical,
    initialSeriesKey: PowerMeterSeriesKeys.apparentPowerVa,
    seriesKey: PowerMeterSeriesKeys.apparentPowerVa,
  ),
  _TileDescriptor(
    widgetId: 'inletTemp',
    type: ThermostatTileType.inletTemp,
    shape: _TileShape.singleBind,
  ),
  _TileDescriptor(
    widgetId: 'outletTemp',
    type: ThermostatTileType.outletTemp,
    shape: _TileShape.singleBind,
  ),
  _TileDescriptor(
    widgetId: 'deltaT',
    type: ThermostatTileType.deltaT,
    shape: _TileShape.delta,
  ),
];
