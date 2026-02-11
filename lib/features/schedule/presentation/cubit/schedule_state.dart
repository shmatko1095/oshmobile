part of 'schedule_cubit.dart';

/// Kind of in-flight operation (for debugging / analytics).
enum ScheduleSavingKind { mode, saveAll }

/// Latest-wins "queued intents" requested while an operation is in-flight.
/// This is a queue in the "logical intent" sense, not execution queue.
/// - mode: last requested mode while saving
/// - saveAll: at least one extra save request while saving
@immutable
class ScheduleQueued {
  final CalendarMode? mode;
  final bool saveAll;

  const ScheduleQueued({
    this.mode,
    this.saveAll = false,
  });

  bool get isEmpty => mode == null && !saveAll;

  ScheduleQueued withMode(CalendarMode m) => ScheduleQueued(mode: m, saveAll: saveAll);

  ScheduleQueued withSaveAll() => ScheduleQueued(mode: mode, saveAll: true);

  ScheduleQueued clearMode() => ScheduleQueued(mode: null, saveAll: saveAll);

  ScheduleQueued clearSaveAll() => ScheduleQueued(mode: mode, saveAll: false);

  ScheduleQueued clear() => const ScheduleQueued();
}

sealed class DeviceScheduleState {
  const DeviceScheduleState();

  CalendarMode get mode;
  List<SchedulePoint> get points;

  bool get dirty => false;
  bool get saving => false;
}

class DeviceScheduleLoading extends DeviceScheduleState {
  final CalendarMode modeHint;

  const DeviceScheduleLoading({this.modeHint = CalendarMode.off});

  @override
  CalendarMode get mode => modeHint;

  @override
  List<SchedulePoint> get points => const <SchedulePoint>[];
}

class DeviceScheduleError extends DeviceScheduleState {
  final String message;
  final CalendarMode modeHint;

  const DeviceScheduleError(this.message, {this.modeHint = CalendarMode.off});

  @override
  CalendarMode get mode => modeHint;

  @override
  List<SchedulePoint> get points => const <SchedulePoint>[];
}

class DeviceScheduleReady extends DeviceScheduleState {
  /// Confirmed snapshot from device.
  final CalendarSnapshot base;

  /// Local override for active mode (draft). Null => use base.mode.
  final CalendarMode? modeOverride;

  /// Local overrides for lists (draft). Only store modes changed locally.
  final Map<CalendarMode, List<SchedulePoint>> listOverrides;

  /// Local override for range (draft). Null => use base.range.
  final ScheduleRange? rangeOverride;

  /// Current in-flight operation, if any.
  final ScheduleSavingKind? savingKind;

  /// One-shot UI message (snackbar).
  final String? flash;

  /// Latest-wins queued intents requested while saving.
  final ScheduleQueued queued;

  const DeviceScheduleReady({
    required this.base,
    this.modeOverride,
    this.listOverrides = const {},
    this.rangeOverride,
    this.savingKind,
    this.flash,
    this.queued = const ScheduleQueued(),
  });

  @override
  bool get dirty => modeOverride != null || listOverrides.isNotEmpty || rangeOverride != null;

  @override
  bool get saving => savingKind != null;

  ScheduleRange get range => rangeOverride ?? base.range;

  /// Draft snapshot shown to UI: base + overrides.
  CalendarSnapshot get snap {
    final effectiveMode = modeOverride ?? base.mode;

    if (listOverrides.isEmpty && modeOverride == null && rangeOverride == null) {
      return base;
    }

    final merged = Map<CalendarMode, List<SchedulePoint>>.from(base.lists);
    listOverrides.forEach((k, v) {
      merged[k] = List.unmodifiable(v);
    });

    return base.copyWith(mode: effectiveMode, lists: merged, range: range);
  }

  @override
  CalendarMode get mode => snap.mode;

  @override
  List<SchedulePoint> get points => snap.pointsFor(snap.mode);

  List<SchedulePoint> listFor(CalendarMode m) => snap.pointsFor(m);

  DeviceScheduleReady copyWith({
    CalendarSnapshot? base,
    CalendarMode? modeOverride,
    bool removeModeOverride = false,
    Map<CalendarMode, List<SchedulePoint>>? listOverrides,
    ScheduleRange? rangeOverride,
    bool clearRangeOverride = false,
    ScheduleSavingKind? savingKind,
    bool clearSavingKind = false,
    String? flash, // pass null to clear
    ScheduleQueued? queued,
  }) {
    return DeviceScheduleReady(
      base: base ?? this.base,
      modeOverride: removeModeOverride ? null : (modeOverride ?? this.modeOverride),
      listOverrides: listOverrides ?? this.listOverrides,
      rangeOverride: clearRangeOverride ? null : (rangeOverride ?? this.rangeOverride),
      savingKind: clearSavingKind ? null : (savingKind ?? this.savingKind),
      flash: flash,
      queued: queued ?? this.queued,
    );
  }
}
