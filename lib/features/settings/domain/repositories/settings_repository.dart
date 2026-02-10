import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';

/// High-level abstraction for device settings (JSON-RPC).
///
/// Responsibility:
/// - Fetch full snapshot from device (retained state or JSON-RPC get).
/// - Save full snapshot (JSON-RPC set).
/// - Stream retained state updates from device.
abstract class SettingsRepository {
  /// Fetch full settings snapshot.
  Future<SettingsSnapshot> fetchAll({bool forceGet = false});

  /// Save full snapshot atomically (JSON-RPC).
  Future<void> saveAll(SettingsSnapshot snapshot, {String? reqId});

  /// Patch selected settings fields (JSON-RPC).
  Future<void> patch(Map<String, dynamic> patch, {String? reqId});

  /// Stream of reported updates.
  Stream<SettingsSnapshot> watchSnapshot();
}
