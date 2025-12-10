import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';

/// High-level abstraction for device settings (shadow-style).
///
/// Responsibility:
/// - Fetch full snapshot from device (via MQTT shadow or other transport).
/// - Save full snapshot (optionally with reqId for ACK correlation).
/// - Stream reported updates from device; key is applied reqId (may be null).
abstract class SettingsRepository {
  /// Fetch full settings snapshot for [deviceSn].
  Future<SettingsSnapshot> fetchAll(String deviceSn);

  /// Save full snapshot atomically.
  ///
  /// Optional [reqId] is echoed by firmware in reported payload
  /// (e.g. in meta.lastAppliedSettingsReqId). If firmware does not support reqId,
  /// it may simply republish reported without correlation.
  Future<void> saveAll(String deviceSn, SettingsSnapshot snapshot, {String? reqId});

  /// Stream of reported updates.
  ///
  /// - `key` is appliedReqId (e.g. meta.lastAppliedSettingsReqId) or null
  ///   if firmware does not provide correlation.
  /// - `value` is the latest merged SettingsSnapshot.
  Stream<MapEntry<String?, SettingsSnapshot>> watchSnapshot(String deviceSn);
}
