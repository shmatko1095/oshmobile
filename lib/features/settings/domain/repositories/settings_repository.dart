import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';

/// High-level abstraction for device settings (JSON-RPC).
///
/// Responsibility:
/// - Fetch full snapshot from device (retained state or JSON-RPC get).
/// - Save full snapshot (JSON-RPC set).
/// - Stream retained state updates from device; key is applied reqId (may be null).
abstract class SettingsRepository {
  /// Fetch full settings snapshot for [deviceSn].
  Future<SettingsSnapshot> fetchAll(String deviceSn, {bool forceGet = false});

  /// Save full snapshot atomically (JSON-RPC).
  Future<void> saveAll(String deviceSn, SettingsSnapshot snapshot, {String? reqId});

  /// Stream of reported updates.
  ///
  /// - `key` is appliedReqId (e.g. meta.lastAppliedSettingsReqId) or null
  ///   if firmware does not provide correlation.
  /// - `value` is the latest merged SettingsSnapshot.
  Stream<MapEntry<String?, SettingsSnapshot>> watchSnapshot(String deviceSn);
}
