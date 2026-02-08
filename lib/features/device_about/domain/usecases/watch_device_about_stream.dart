import 'package:oshmobile/features/device_about/domain/repositories/device_about_repository.dart';

class WatchDeviceAboutStream {
  final DeviceAboutRepository repo;

  const WatchDeviceAboutStream(this.repo);

  Stream<Map<String, dynamic>> call() => repo.watchState();
}
