import 'package:intl/intl.dart';

class ConnectionInfo {
  final bool online;
  final DateTime? timestamp;

  ConnectionInfo({required this.online, this.timestamp});

  factory ConnectionInfo.fromJson(Map<String, dynamic> json) {
    return ConnectionInfo(
      online: json['online'] == true,
      timestamp: _parseUnix(json['timestamp']),
    );
  }

  String get timestampText => timestamp == null ? '' : DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp!.toLocal());

  static DateTime? _parseUnix(dynamic v) {
    if (v == null) return null;
    final d = v is num ? v.toDouble() : double.tryParse(v.toString());
    if (d == null) return null;

    final millis = d >= 1e12 ? d.toInt() : (d * 1000).round();
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
}
