import 'package:meta/meta.dart';

/// High-level states of Wi-Fi connection process.
enum WifiConnectState {
  idle,
  connecting,
  obtainingIp,
  success,
  failed,
}

/// Domain model for connection status updates coming from device.
@immutable
class WifiConnectStatus {
  final WifiConnectState state;
  final String message; // raw device message, for logging/UI if needed.

  const WifiConnectStatus({
    required this.state,
    required this.message,
  });

  factory WifiConnectStatus.fromJson(Map<String, dynamic> json) {
    final stateRaw = json['state'] as String? ?? '';
    final msg = json['message'] as String? ?? '';

    WifiConnectState state;
    switch (stateRaw) {
      case 'connecting':
        // Device uses the same state for "connecting" and "obtaining_ip",
        // so we rely on the message to distinguish.
        if (msg == 'obtaining_ip') {
          state = WifiConnectState.obtainingIp;
        } else {
          state = WifiConnectState.connecting;
        }
        break;
      case 'success':
        state = WifiConnectState.success;
        break;
      case 'failed':
        state = WifiConnectState.failed;
        break;
      default:
        state = WifiConnectState.idle;
        break;
    }

    return WifiConnectStatus(
      state: state,
      message: msg,
    );
  }
}
