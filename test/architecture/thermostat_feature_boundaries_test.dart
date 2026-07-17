import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user guide does not depend on thermostat presentation', () {
    final violations = _dartFiles('lib/features/user_guide')
        .where(
          (file) => file.readAsStringSync().contains(
                'package:oshmobile/features/devices/',
              ),
        )
        .map((file) => file.path)
        .toList();

    expect(violations, isEmpty);
  });

  test('involved domain layers do not import data or presentation', () {
    final violations = <String>[];
    for (final directory in <String>[
      'lib/features/devices/details/domain',
      'lib/features/telemetry_history/domain',
      'lib/features/user_guide/domain',
    ]) {
      for (final file in _dartFiles(directory)) {
        final source = file.readAsStringSync();
        if (source.contains('/data/') || source.contains('/presentation/')) {
          violations.add(file.path);
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('thermostat presenter uses the public history adapter only', () {
    final source = File(
      'lib/features/devices/details/presentation/presenters/'
      'thermostat_presenters.dart',
    ).readAsStringSync();

    expect(
      source,
      isNot(contains('features/telemetry_history/presentation/models/')),
    );
    expect(
      source,
      isNot(contains('features/telemetry_history/presentation/'
          'open_telemetry_history.dart')),
    );
  });

  test('new architecture areas keep at most one class per source file', () {
    final violations = <String>[];
    final classPattern = RegExp(
      r'^\s*(?:(?:abstract\s+(?:interface\s+)?)|final\s+|sealed\s+)?class\s+',
      multiLine: true,
    );

    for (final directory in <String>[
      'lib/features/devices/details/presentation/user_guide',
      'lib/features/telemetry_history/domain/models',
      'lib/features/user_guide',
    ]) {
      for (final file in _dartFiles(directory)) {
        final count = classPattern.allMatches(file.readAsStringSync()).length;
        if (count > 1) violations.add('${file.path}: $count classes');
      }
    }

    expect(violations, isEmpty);
  });
}

Iterable<File> _dartFiles(String path) {
  return Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}
