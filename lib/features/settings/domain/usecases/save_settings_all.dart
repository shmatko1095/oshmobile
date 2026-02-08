import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/repositories/settings_repository.dart';

class SaveSettingsAll {
  final SettingsRepository repo;

  const SaveSettingsAll(this.repo);

  Future<void> call(SettingsSnapshot snapshot, {String? reqId}) => repo.saveAll(snapshot, reqId: reqId);
}
