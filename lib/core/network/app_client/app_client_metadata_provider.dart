import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import 'package:oshmobile/core/network/app_client/app_client_metadata.dart';

abstract interface class AppClientMetadataProvider {
  Future<AppClientMetadata> getMetadata();
}

class PackageInfoAppClientMetadataProvider
    implements AppClientMetadataProvider {
  PackageInfoAppClientMetadataProvider({PackageInfo? packageInfo})
      : _packageInfo = packageInfo;

  final PackageInfo? _packageInfo;

  AppClientMetadata? _cached;

  @override
  Future<AppClientMetadata> getMetadata() async {
    final cached = _cached;
    if (cached != null) {
      return cached;
    }

    final packageInfo = _packageInfo ?? await PackageInfo.fromPlatform();
    final appVersion = packageInfo.version.trim();
    final build = int.tryParse(packageInfo.buildNumber.trim());

    final metadata = AppClientMetadata(
      platform: _resolvePlatform(),
      appVersion: appVersion,
      build: build,
    );
    _cached = metadata;
    return metadata;
  }

  String _resolvePlatform() {
    if (Platform.isIOS) return 'ios';
    return 'android';
  }
}
