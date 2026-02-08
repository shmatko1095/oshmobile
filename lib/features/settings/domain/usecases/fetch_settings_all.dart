import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/repositories/settings_repository.dart';

class FetchSettingsAll {
  final SettingsRepository repo;

  const FetchSettingsAll(this.repo);

  Future<SettingsSnapshot> call(String deviceSn, {bool forceGet = false}) =>
      repo.fetchAll(deviceSn, forceGet: forceGet);
}
