import 'package:meta/meta.dart';

/// Authentication type reported by the device.
enum WifiAuthType {
  open,
  wep,
  wpa,
  wpa2,
  wpa2Ent,
  wpa3,
  unknown,
}

@immutable
class WifiNetwork {
  final String ssid;
  final String bssid;
  final int rssi;
  final WifiAuthType auth;

  const WifiNetwork({
    required this.ssid,
    required this.bssid,
    required this.rssi,
    required this.auth,
  });

  factory WifiNetwork.fromJson(Map<String, dynamic> json) {
    return WifiNetwork(
      ssid: json['ssid'] as String? ?? '',
      bssid: json['bssid'] as String? ?? '',
      rssi: (json['rssi'] as num?)?.toInt() ?? 0,
      auth: _mapAuth(json['auth'] as String?),
    );
  }

  static WifiAuthType _mapAuth(String? raw) {
    switch (raw) {
      case 'open':
        return WifiAuthType.open;
      case 'wep':
        return WifiAuthType.wep;
      case 'wpa':
        return WifiAuthType.wpa;
      case 'wpa2':
        return WifiAuthType.wpa2;
      case 'wpa2_ent':
        return WifiAuthType.wpa2Ent;
      case 'wpa3':
        return WifiAuthType.wpa3;
      default:
        return WifiAuthType.unknown;
    }
  }
}
