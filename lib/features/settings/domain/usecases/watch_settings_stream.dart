import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/repositories/settings_repository.dart';

class WatchSettingsStream {
  final SettingsRepository repo;

  const WatchSettingsStream(this.repo);

  Stream<SettingsSnapshot> call() => repo.watchSnapshot();
}
