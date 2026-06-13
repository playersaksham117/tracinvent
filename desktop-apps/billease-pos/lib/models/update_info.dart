class AppVersion {
  final int major;
  final int minor;
  final int patch;
  final String? buildNumber;

  AppVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.buildNumber,
  });

  String get version => '$major.$minor.$patch';
  String get fullVersion => buildNumber != null ? '$version+$buildNumber' : version;

  factory AppVersion.fromString(String version) {
    final parts = version.split('+');
    final versionParts = parts[0].split('.');

    return AppVersion(
      major: int.parse(versionParts[0]),
      minor: int.parse(versionParts.length > 1 ? versionParts[1] : '0'),
      patch: int.parse(versionParts.length > 2 ? versionParts[2] : '0'),
      buildNumber: parts.length > 1 ? parts[1] : null,
    );
  }

  bool isNewerThan(AppVersion other) {
    if (major != other.major) return major > other.major;
    if (minor != other.minor) return minor > other.minor;
    return patch > other.patch;
  }
}
