import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';
import 'package:oshmobile/generated/l10n.dart';

class TemperatureMinimalPanel extends StatefulWidget {
  const TemperatureMinimalPanel({
    super.key,
    required this.currentBind,
    required this.sensorsBind,
    required this.currentTargetBind,
    required this.nextTargetBind,
    this.onTap,
    this.unit = '°C',
    this.height,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.borderRadius = AppPalette.radiusXl,
  });

  final String currentBind;
  final String sensorsBind;
  final String currentTargetBind;
  final String nextTargetBind;
  final String unit;
  final double? height;
  final EdgeInsets padding;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  State<TemperatureMinimalPanel> createState() =>
      _TemperatureMinimalPanelState();
}

class _TemperatureMinimalPanelState extends State<TemperatureMinimalPanel> {
  late final PageController _pageCtrl;
  int _page = 0;
  final List<String> _sensorOrder = <String>[];
  bool _initialPageResolved = false;
  int? _pendingJumpTarget;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  num? _asNum(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return false;
  }

  String _fmtNum(num? v, {int fractionDigits = 1}) {
    if (v == null) return '—';
    final d = v.toDouble();
    if (d.isNaN || d.isInfinite) return '—';
    return d.toStringAsFixed(fractionDigits);
  }

  String _fmtTime(BuildContext context, TimeOfDay t) {
    final alwaysUse24h =
        MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
    return MaterialLocalizations.of(context).formatTimeOfDay(
      t,
      alwaysUse24HourFormat: alwaysUse24h,
    );
  }

  List<_SensorCardData> _parseSensors(dynamic raw) {
    if (raw is! List) return const <_SensorCardData>[];

    final parsed = <_SensorCardData>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = item.cast<String, dynamic>();
      final id = (m['id'] ?? '').toString();
      if (id.isEmpty) continue;

      final name = (m['name']?.toString().trim().isNotEmpty ?? false)
          ? m['name'].toString().trim()
          : id;
      final kind = m['kind']?.toString();
      final ref = _asBool(m['ref']);

      final tempRaw = _asNum(m['temp']);
      final humidityRaw = _asNum(m['humidity']);
      final tempValid = _asBool(m['temp_valid']) && tempRaw != null;
      final humidityValid = _asBool(m['humidity_valid']) && humidityRaw != null;

      parsed.add(
        _SensorCardData(
          id: id,
          name: name,
          kind: kind,
          ref: ref,
          tempValid: tempValid,
          humidityValid: humidityValid,
          temp: tempValid ? tempRaw.toDouble() : null,
          humidity: humidityValid ? humidityRaw.toDouble() : null,
        ),
      );
    }

    if (parsed.isEmpty) {
      _sensorOrder.clear();
      return parsed;
    }

    final incomingIds = parsed.map((s) => s.id).toSet();
    _sensorOrder.removeWhere((id) => !incomingIds.contains(id));

    final knownIds = _sensorOrder.toSet();
    for (final sensor in parsed) {
      if (!knownIds.contains(sensor.id)) {
        _sensorOrder.add(sensor.id);
        knownIds.add(sensor.id);
      }
    }

    final byId = <String, _SensorCardData>{
      for (final sensor in parsed) sensor.id: sensor,
    };

    return _sensorOrder
        .map((id) => byId[id])
        .whereType<_SensorCardData>()
        .toList(growable: false);
  }

  void _scheduleJumpToPage(int target) {
    if (_pendingJumpTarget == target) return;
    _pendingJumpTarget = target;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final planned = _pendingJumpTarget;
      _pendingJumpTarget = null;
      if (planned == null || !_pageCtrl.hasClients) return;
      _pageCtrl.jumpToPage(planned);
    });
  }

  void _ensureInitialPage(List<_SensorCardData> sensors) {
    if (sensors.isEmpty) {
      _initialPageResolved = false;
      _page = 0;
      return;
    }

    final maxIndex = sensors.length - 1;
    if (!_initialPageResolved) {
      final mainIndex = sensors.indexWhere((s) => s.ref);
      final target = mainIndex >= 0 ? mainIndex : 0;
      _initialPageResolved = true;
      _page = target;
      _scheduleJumpToPage(target);
      return;
    }

    if (_page > maxIndex) {
      _page = maxIndex;
      _scheduleJumpToPage(maxIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlState = context.select<DeviceSnapshotCubit, Map<String, dynamic>>(
      (c) => c.state.controlState.data ?? const <String, dynamic>{},
    );

    final currentTarget = _asNum(readBind(controlState, widget.currentTargetBind));
    final nextTarget = readBind(controlState, widget.nextTargetBind);
    final nextTime = _nextTargetTime(nextTarget);

    final targetLine = currentTarget == null
        ? null
        : S.of(context).Target('${_fmtNum(currentTarget)}${widget.unit}');
    final nextLine = nextTarget is! Map || nextTime == null
        ? null
        : S.of(context).NextAt(
            '${_fmtNum(_asNum(nextTarget['temp']))}${widget.unit}',
            _fmtTime(context, nextTime),
          );

    final sensors = _parseSensors(readBind(controlState, widget.sensorsBind));
    _ensureInitialPage(sensors);
    final fallbackCurrent = _asNum(readBind(controlState, widget.currentBind));

    final content = sensors.isEmpty
        ? _FallbackCard(
            temperatureText: _fmtNum(fallbackCurrent),
            unit: widget.unit,
            borderRadius: widget.borderRadius,
            onTap: widget.onTap,
            targetLine: targetLine,
            nextLine: nextLine,
          )
        : _SensorCarousel(
            pageController: _pageCtrl,
            pageIndex: _page,
            sensors: sensors,
            unit: widget.unit,
            borderRadius: widget.borderRadius,
            onTap: widget.onTap,
            targetLine: targetLine,
            nextLine: nextLine,
            onPageChanged: (nextPage) {
              if (_page == nextPage) return;
              setState(() => _page = nextPage);
            },
            formatNum: _fmtNum,
          );

    final panel = Padding(
      padding: widget.padding,
      child: content,
    );

    if (widget.height != null) {
      return SizedBox(height: widget.height, child: panel);
    }
    return panel;
  }

  TimeOfDay? _nextTargetTime(dynamic raw) {
    if (raw is! Map) return null;
    final hour = _asNum(raw['hour'])?.toInt();
    final minute = _asNum(raw['minute'])?.toInt();
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}

class _FallbackCard extends StatelessWidget {
  const _FallbackCard({
    required this.temperatureText,
    required this.unit,
    required this.borderRadius,
    required this.onTap,
    required this.targetLine,
    required this.nextLine,
  });

  final String temperatureText;
  final String unit;
  final double borderRadius;
  final VoidCallback? onTap;
  final String? targetLine;
  final String? nextLine;

  @override
  Widget build(BuildContext context) {
    return AppSolidCard(
      onTap: onTap,
      radius: borderRadius,
      padding: EdgeInsets.zero,
      backgroundColor: AppPalette.surfaceRaised,
      borderColor: AppPalette.accentPrimary.withValues(alpha: 0.26),
      child: Stack(
        children: [
          _MainCardAccentLayer(borderRadius: borderRadius),
          Padding(
            padding: const EdgeInsets.all(AppPalette.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Temperature',
                  style: TextStyle(
                    color: AppPalette.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      temperatureText,
                      style: const TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 78,
                        fontWeight: FontWeight.w300,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        unit,
                        style: const TextStyle(
                          color: AppPalette.textSecondary,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                _ScheduleMetaBlock(
                  targetLine: targetLine,
                  nextLine: nextLine,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorCarousel extends StatelessWidget {
  const _SensorCarousel({
    required this.pageController,
    required this.pageIndex,
    required this.sensors,
    required this.unit,
    required this.borderRadius,
    required this.onTap,
    required this.targetLine,
    required this.nextLine,
    required this.onPageChanged,
    required this.formatNum,
  });

  final PageController pageController;
  final int pageIndex;
  final List<_SensorCardData> sensors;
  final String unit;
  final double borderRadius;
  final VoidCallback? onTap;
  final String? targetLine;
  final String? nextLine;
  final ValueChanged<int> onPageChanged;
  final String Function(num? value, {int fractionDigits}) formatNum;

  @override
  Widget build(BuildContext context) {
    final hasRefSensor = sensors.any((s) => s.ref);
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: pageController,
            padEnds: true,
            itemCount: sensors.length,
            onPageChanged: onPageChanged,
            itemBuilder: (_, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _SensorCard(
                sensor: sensors[index],
                unit: unit,
                borderRadius: borderRadius,
                onTap: onTap,
                targetLine: targetLine,
                nextLine: nextLine,
                showScheduleMeta:
                    hasRefSensor ? sensors[index].ref : index == 0,
                formatNum: formatNum,
              ),
            ),
          ),
        ),
        if (sensors.length > 1) ...[
          const SizedBox(height: 10),
          _Dots(
            count: sensors.length,
            active: pageIndex,
          ),
        ],
      ],
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.sensor,
    required this.unit,
    required this.borderRadius,
    required this.onTap,
    required this.targetLine,
    required this.nextLine,
    required this.showScheduleMeta,
    required this.formatNum,
  });

  final _SensorCardData sensor;
  final String unit;
  final double borderRadius;
  final VoidCallback? onTap;
  final String? targetLine;
  final String? nextLine;
  final bool showScheduleMeta;
  final String Function(num? value, {int fractionDigits}) formatNum;

  @override
  Widget build(BuildContext context) {
    final hasAnyData = sensor.tempValid || sensor.humidityValid;
    final kindLabel = (sensor.kind ?? '').trim();
    final isMainCard = showScheduleMeta;

    return AppSolidCard(
      onTap: onTap,
      radius: borderRadius,
      padding: EdgeInsets.zero,
      backgroundColor: AppPalette.surfaceRaised,
      borderColor:
          isMainCard ? AppPalette.accentPrimary.withValues(alpha: 0.24) : null,
      child: Stack(
        children: [
          if (isMainCard) _MainCardAccentLayer(borderRadius: borderRadius),
          Padding(
            padding: const EdgeInsets.all(AppPalette.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sensor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppPalette.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    if (sensor.ref)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              AppPalette.accentPrimary.withValues(alpha: 0.22),
                          borderRadius:
                              BorderRadius.circular(AppPalette.radiusPill),
                        ),
                        child: const Text(
                          'Main',
                          style: TextStyle(
                            color: AppPalette.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                if (kindLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    kindLabel,
                    style: const TextStyle(
                      color: AppPalette.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const Spacer(),
                if (sensor.tempValid)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatNum(sensor.temp),
                        style: const TextStyle(
                          color: AppPalette.textPrimary,
                          fontSize: 72,
                          fontWeight: FontWeight.w300,
                          height: 0.95,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          unit,
                          style: const TextStyle(
                            color: AppPalette.textSecondary,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'No temperature data',
                    style: TextStyle(
                      color: AppPalette.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                const SizedBox(height: 12),
                if (sensor.humidityValid)
                  Row(
                    children: [
                      const Icon(Icons.water_drop_rounded,
                          size: 18, color: AppPalette.accentPrimary),
                      const SizedBox(width: 6),
                      Text(
                        '${formatNum(sensor.humidity, fractionDigits: 0)}%',
                        style: const TextStyle(
                          color: AppPalette.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  )
                else if (!hasAnyData)
                  const Text(
                    'No sensor data',
                    style: TextStyle(
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                if (showScheduleMeta)
                  _ScheduleMetaBlock(
                    targetLine: targetLine,
                    nextLine: nextLine,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MainCardAccentLayer extends StatelessWidget {
  const _MainCardAccentLayer({
    required this.borderRadius,
  });

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppPalette.accentPrimary.withValues(alpha: 0.14),
                AppPalette.accentPrimary.withValues(alpha: 0.06),
                Colors.transparent,
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleMetaBlock extends StatelessWidget {
  const _ScheduleMetaBlock({
    required this.targetLine,
    required this.nextLine,
  });

  final String? targetLine;
  final String? nextLine;

  @override
  Widget build(BuildContext context) {
    if (targetLine == null && nextLine == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Divider(
          color: AppPalette.separator,
          thickness: 0.8,
          height: 1,
        ),
        const SizedBox(height: 8),
        if (targetLine != null)
          Text(
            targetLine!,
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (nextLine != null) ...[
          const SizedBox(height: 2),
          Text(
            nextLine!,
            style: const TextStyle(
              color: AppPalette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.active,
  });

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppPalette.motionFast,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 6,
            width: i == active ? 16 : 6,
            decoration: BoxDecoration(
              color: i == active
                  ? AppPalette.accentPrimary
                  : AppPalette.textMuted.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppPalette.radiusPill),
            ),
          ),
      ],
    );
  }
}

class _SensorCardData {
  const _SensorCardData({
    required this.id,
    required this.name,
    required this.kind,
    required this.ref,
    required this.tempValid,
    required this.humidityValid,
    required this.temp,
    required this.humidity,
  });

  final String id;
  final String name;
  final String? kind;
  final bool ref;
  final bool tempValid;
  final bool humidityValid;
  final double? temp;
  final double? humidity;
}
