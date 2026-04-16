class MobileClientPolicy {
  const MobileClientPolicy({
    required this.minSupportedVersion,
    required this.latestVersion,
    required this.storeUrl,
    required this.policyVersion,
    required this.checkedAt,
    required this.fetchedAt,
  });

  final String minSupportedVersion;
  final String latestVersion;
  final String storeUrl;
  final int policyVersion;
  final DateTime checkedAt;
  final DateTime fetchedAt;

  Map<String, dynamic> toJson() {
    return {
      'min_supported_version': minSupportedVersion,
      'latest_version': latestVersion,
      'store_url': storeUrl,
      'policy_version': policyVersion,
      'checked_at': checkedAt.toUtc().toIso8601String(),
      'fetched_at': fetchedAt.toUtc().toIso8601String(),
    };
  }

  static MobileClientPolicy? fromJson(Map<String, dynamic> json) {
    final minSupportedVersion =
        json['min_supported_version']?.toString().trim() ?? '';
    final latestVersion = json['latest_version']?.toString().trim() ?? '';
    final storeUrl = json['store_url']?.toString().trim() ?? '';

    if (minSupportedVersion.isEmpty ||
        latestVersion.isEmpty ||
        storeUrl.isEmpty) {
      return null;
    }

    final policyVersion = _asInt(json['policy_version']);
    if (policyVersion == null || policyVersion <= 0) {
      return null;
    }

    final checkedAt = DateTime.tryParse(json['checked_at']?.toString() ?? '');
    final fetchedAt = DateTime.tryParse(json['fetched_at']?.toString() ?? '');
    if (checkedAt == null || fetchedAt == null) {
      return null;
    }

    return MobileClientPolicy(
      minSupportedVersion: minSupportedVersion,
      latestVersion: latestVersion,
      storeUrl: storeUrl,
      policyVersion: policyVersion,
      checkedAt: checkedAt.toUtc(),
      fetchedAt: fetchedAt.toUtc(),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      return int.tryParse(text);
    }
    return null;
  }
}
