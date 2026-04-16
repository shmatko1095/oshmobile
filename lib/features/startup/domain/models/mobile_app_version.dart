class MobileAppVersion implements Comparable<MobileAppVersion> {
  const MobileAppVersion({
    required this.major,
    required this.minor,
    required this.patch,
  });

  static final RegExp _versionPattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');

  final int major;
  final int minor;
  final int patch;

  static MobileAppVersion? tryParse(String raw) {
    final text = raw.trim();
    final match = _versionPattern.firstMatch(text);
    if (match == null) {
      return null;
    }

    return MobileAppVersion(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
    );
  }

  @override
  int compareTo(MobileAppVersion other) {
    if (major != other.major) {
      return major.compareTo(other.major);
    }
    if (minor != other.minor) {
      return minor.compareTo(other.minor);
    }
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => '$major.$minor.$patch';
}
