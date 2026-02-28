import 'package:oshmobile/core/profile/models/device_profile_bundle.dart';

abstract interface class ProfileBundleRepository {
  Future<DeviceProfileBundle> fetchBundle({
    required String serial,
    required String modelId,
    Set<String> negotiatedSchemas,
  });
}
