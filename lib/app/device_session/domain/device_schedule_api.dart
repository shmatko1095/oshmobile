part of 'device_facade.dart';

abstract interface class DeviceScheduleApi {
  Set<ScheduleSetpointKind> get supportedSetpointKinds;
  CalendarSnapshot? get current;

  Stream<CalendarSnapshot> watch();

  Future<CalendarSnapshot> get({bool force = false});

  Future<void> commandSetMode(
    CalendarMode mode, {
    String source = 'unknown',
  });

  void patchRange(ScheduleRange range);

  void patchList(CalendarMode mode, List<SchedulePoint> points);

  void patchPoint(int index, SchedulePoint point);

  void removePoint(int index);

  void addPoint([SchedulePoint? point, int stepMinutes = 15]);

  Future<void> save();

  void discardLocalChanges();
}
