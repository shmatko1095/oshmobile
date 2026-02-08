import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/repositories/settings_repository.dart';

class FetchSettingsAll {
  final SettingsRepository repo;

  const FetchSettingsAll(this.repo);

  Future<SettingsSnapshot> call({bool forceGet = false}) => repo.fetchAll(forceGet: forceGet);
}
