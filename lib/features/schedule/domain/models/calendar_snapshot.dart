import 'dart:collection';

import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

/// Immutable snapshot of schedule state.
/// - Internally deep-freezes both the map and all lists to prevent accidental mutation.
/// - Guarantees that ALL modes exist in [lists] (missing ones are filled with empty lists).
class CalendarSnapshot {
  final CalendarMode mode;
  final ScheduleRange range;

  /// Unmodifiable map with unmodifiable lists inside.
  /// Type remains `Map<CalendarMode, List<SchedulePoint>>` for compatibility,
  /// but the concrete instances are `UnmodifiableMapView` and `UnmodifiableListView`.
  final Map<CalendarMode, List<SchedulePoint>> lists;

  /// Private normalized constructor. Use the public factory below.
  CalendarSnapshot._({
    required this.mode,
    required this.range,
    required Map<CalendarMode, List<SchedulePoint>> lists,
  }) : lists = _freezeAndFill(lists);

  /// Public factory that normalizes and deep-freezes the input.
  factory CalendarSnapshot({
    required CalendarMode mode,
    ScheduleRange? range,
    required Map<CalendarMode, List<SchedulePoint>> lists,
  }) {
    return CalendarSnapshot._(mode: mode, range: range ?? const ScheduleRange.defaults(), lists: lists);
  }

  /// Returns a read-only view of points for the given mode.
  List<SchedulePoint> pointsFor(CalendarMode m) => List.unmodifiable(lists[m] ?? const <SchedulePoint>[]);

  /// Standard copyWith that also keeps deep immutability guarantees.
  CalendarSnapshot copyWith({
    CalendarMode? mode,
    ScheduleRange? range,
    Map<CalendarMode, List<SchedulePoint>>? lists,
  }) =>
      CalendarSnapshot._(
        mode: mode ?? this.mode,
        range: range ?? this.range,
        lists: lists ?? this.lists,
      );

  /// Convenient empty snapshot with the given [mode] (default OFF),
  /// and empty lists for all modes.
  static CalendarSnapshot empty([CalendarMode mode = CalendarMode.off]) =>
      CalendarSnapshot._(mode: mode, range: const ScheduleRange.defaults(), lists: const {});

  // --------------------------------------------------------------------------
  // Internals
  // --------------------------------------------------------------------------

  /// Freeze input map and ensure all known modes exist with empty unmodifiable lists.
  static Map<CalendarMode, List<SchedulePoint>> _freezeAndFill(Map<CalendarMode, List<SchedulePoint>> input) {
    // 1) Deep-freeze lists for modes present in the input.
    final frozen = <CalendarMode, List<SchedulePoint>>{
      for (final entry in input.entries) entry.key: UnmodifiableListView<SchedulePoint>(entry.value),
    };

    // 2) Ensure all modes exist (missing -> empty list).
    for (final m in CalendarMode.listModes) {
      frozen.putIfAbsent(m, () => const <SchedulePoint>[]);
    }

    // 3) Freeze the map itself.
    return UnmodifiableMapView<CalendarMode, List<SchedulePoint>>(frozen);
  }
}
