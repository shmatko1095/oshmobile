part of 'device_about_cubit.dart';

sealed class DeviceAboutState {
  const DeviceAboutState();

  Map<String, dynamic>? get maybeData => null;
}

class DeviceAboutLoading extends DeviceAboutState {
  const DeviceAboutLoading();
}

class DeviceAboutReady extends DeviceAboutState {
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  const DeviceAboutReady({
    required this.data,
    required this.receivedAt,
  });

  @override
  Map<String, dynamic> get maybeData => data;
}

class DeviceAboutError extends DeviceAboutState {
  final String message;
  final Map<String, dynamic>? last;

  const DeviceAboutError(this.message, {this.last});

  @override
  Map<String, dynamic>? get maybeData => last;
}
