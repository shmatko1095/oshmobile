import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/settings/data/settings_contract_schema_catalog.dart';
import 'package:oshmobile/features/settings/data/settings_jsonrpc_codec.dart';
import 'package:oshmobile/features/settings/data/settings_payload_validator.dart';

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

  test('settings schema catalog exposes control in set and patch schemas', () {
    final setProps =
        SettingsContractSchemaCatalog.settingsSetV1['properties'] as Map;
    final patchProps =
        SettingsContractSchemaCatalog.settingsPatchV1['properties'] as Map;

    expect(setProps.containsKey('control'), isTrue);
    expect(patchProps.containsKey('control'), isTrue);
  });
}
