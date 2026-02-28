import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/common/entities/device/known_device_models.dart';
import 'package:oshmobile/features/settings/data/json_schema_settings_ui_schema_builder.dart';
import 'package:oshmobile/features/settings/data/settings_jsonrpc_codec.dart';
import 'package:oshmobile/features/settings/data/settings_payload_validator.dart';
import 'support/thermostat_profile_bundle_fixture.dart';

Map<String, dynamic> _baseSettingsPayload() => {
      'display': {
        'activeBrightness': 100,
        'idleBrightness': 50,
        'idleTime': 10,
        'dimOnIdle': true,
        'language': 'en',
      },
      'update': {
        'autoUpdateEnabled': true,
        'updateAtMidnight': false,
        'checkIntervalMin': 60,
      },
      'time': {
        'auto': true,
        'timeZone': 2,
      },
    };

void main() {
  test('settings set payload accepts optional control section', () {
    final payload = _baseSettingsPayload()
      ..['control'] = {
        'model': 'tpi',
        'maxFloorTemp': 35.5,
        'maxFloorTempLimitEnabled': true,
        'maxFloorTempFailSafe': false,
      };

    expect(validateSettingsSetPayload(payload), isTrue);
    expect(SettingsJsonRpcCodec.decodeBody(payload), isNotNull);
  });

  test('settings set payload rejects control without model', () {
    final payload = _baseSettingsPayload()
      ..['control'] = {
        'maxFloorTemp': 35.5,
      };

    expect(validateSettingsSetPayload(payload), isFalse);
  });

  test('settings patch payload accepts control.model', () {
    final patch = {
      'control': {'model': 'r2c'}
    };

    expect(validateSettingsPatchPayload(patch), isTrue);
    expect(SettingsJsonRpcCodec.encodePatch(patch), isNotEmpty);
  });

  test('settings patch payload rejects invalid control values', () {
    final badModel = {
      'control': {'model': 'pid'}
    };
    final badMaxFloorTemp = {
      'control': {'model': 'tpi', 'maxFloorTemp': 60}
    };

    expect(validateSettingsPatchPayload(badModel), isFalse);
    expect(validateSettingsPatchPayload(badMaxFloorTemp), isFalse);
  });

  test('settings UI schema is derived from device profile bundle', () {
    final bundle = createThermostatProfileBundle(
      serial: 'TEST-SN',
      modelId: t1aFlWzeModelId,
      negotiatedSchemas: const <String>{
        'settings@1',
        'schedule@1',
        'telemetry@1',
        'sensors@1',
      },
    );

    final schema = const ProfileBundleSettingsUiSchemaBuilder().build(
      bundle: bundle,
    );

    expect(schema.group('display')?.titleKey, 'Display');
    expect(
      schema.field('control.maxFloorTemp')?.titleKey,
      'Maximum floor temperature',
    );
    expect(
      schema.field('display.language')?.enumValues,
      containsAll(const <String>['en', 'uk']),
    );
  });

  test('settings UI respects negotiated write support and feature flags', () {
    final bundle = createThermostatProfileBundle(
      serial: 'TEST-SN',
      modelId: t1aFlWzeModelId,
      negotiatedSchemas: const <String>{'settings@1'},
    );

    final schema = const ProfileBundleSettingsUiSchemaBuilder().build(
      bundle: bundle.copyWith(
        readableDomains: const <String>{'settings'},
        patchableDomains: const <String>{},
        settableDomains: const <String>{},
        negotiatedFeaturesByDomain: const <String, Set<String>>{
          'settings': <String>{},
        },
      ),
    );

    expect(schema.field('display.activeBrightness')?.writable, isFalse);
    expect(schema.field('control.maxFloorTemp'), isNull);
    expect(schema.field('display.language'), isNull);
  });
}
