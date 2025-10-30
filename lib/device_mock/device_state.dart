/// Minimal in-memory state for the mock device.
class DeviceState {
  double tcur;
  double ttarget;
  String mode; // off | heat | eco | schedule
  String output; // on | off
  int scheduleRevision;
  String fwVersion;
  bool online;
  DateTime lastUpdate;

  DeviceState({
    required this.tcur,
    required this.ttarget,
    required this.mode,
    required this.output,
    this.scheduleRevision = 0,
    this.fwVersion = '1.0.3',
    this.online = false,
    DateTime? lastUpdate,
  }) : lastUpdate = lastUpdate ?? DateTime.now();

  Map<String, dynamic> toReported(String deviceId) => {
        'ver': '1',
        'device_id': deviceId,
        'ts': DateTime.now().toUtc().toIso8601String(),
        'reported': {
          'tcur': double.parse(tcur.toStringAsFixed(1)),
          'ttarget': double.parse(ttarget.toStringAsFixed(1)),
          'mode': mode,
          'output': output,
          'schedule_revision': scheduleRevision,
          'energy': {'p': output == 'on' ? 65.0 : 0.0, 'wh_day': 420}
        }
      };

  Map<String, dynamic> status(String deviceId) => {
        'ver': '1',
        'device_id': deviceId,
        'online': online,
        'fw': fwVersion,
        'ts': DateTime.now().toUtc().toIso8601String()
      };
}
