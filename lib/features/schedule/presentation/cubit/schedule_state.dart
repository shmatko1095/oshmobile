part of 'schedule_cubit.dart';

sealed class DeviceScheduleState {
  const DeviceScheduleState();

  CalendarMode get mode;

  List<SchedulePoint> get points; // current list by active mode
}

class DeviceScheduleLoading extends DeviceScheduleState {
  final CalendarMode modeHint;

  const DeviceScheduleLoading({this.modeHint = CalendarMode.off});

  @override
  CalendarMode get mode => modeHint;

  @override
  List<SchedulePoint> get points => const [];
}

class DeviceScheduleError extends DeviceScheduleState {
  final String message;
  final CalendarMode modeHint;

  const DeviceScheduleError(this.message, {this.modeHint = CalendarMode.off});

  @override
  CalendarMode get mode => modeHint;

  @override
  List<SchedulePoint> get points => const [];
}

class DeviceScheduleReady extends DeviceScheduleState {
  final CalendarSnapshot snap; // contains active mode + lists
  final bool dirty;
  final bool saving;
  final String? flash;

  const DeviceScheduleReady({
    required this.snap,
    this.dirty = false,
    this.saving = false,
    this.flash,
  });

  @override
  CalendarMode get mode => snap.mode;

  @override
  List<SchedulePoint> get points => snap.pointsFor(snap.mode);

  DeviceScheduleReady copyWith({
    CalendarSnapshot? snap,
    bool? dirty,
    bool? saving,
    String? flash,
  }) =>
      DeviceScheduleReady(
        snap: snap ?? this.snap,
        dirty: dirty ?? this.dirty,
        saving: saving ?? this.saving,
        flash: flash,
      );
}
