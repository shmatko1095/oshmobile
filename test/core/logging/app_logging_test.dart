import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:oshmobile/core/logging/app_logging.dart';

void main() {
  group('AppLogging bootstrap policy', () {
    test('debug/profile policy logs fine, warning and severe', () async {
      final lines = <String>[];

      AppLogging.bootstrap(
        isReleaseMode: false,
        enableVerboseLogs: false,
        sink: lines.add,
      );

      final logger = Logger('policy.debug');
      logger.fine('fine-message');
      logger.warning('warn-message');
      logger.severe('severe-message');

      await Future<void>.delayed(Duration.zero);

      final output = lines.join('\n');
      expect(output, contains('FINE policy.debug: fine-message'));
      expect(output, contains('WARNING policy.debug: warn-message'));
      expect(output, contains('SEVERE policy.debug: severe-message'));
    });

    test('release policy logs only severe', () async {
      final lines = <String>[];

      AppLogging.bootstrap(
        isReleaseMode: true,
        enableVerboseLogs: false,
        sink: lines.add,
      );

      final logger = Logger('policy.release');
      logger.fine('fine-message');
      logger.warning('warn-message');
      logger.severe('severe-message');

      await Future<void>.delayed(Duration.zero);

      final output = lines.join('\n');
      expect(output, isNot(contains('fine-message')));
      expect(output, isNot(contains('warn-message')));
      expect(output, contains('SEVERE policy.release: severe-message'));
    });

    test('release + verbose override logs fine and warning', () async {
      final lines = <String>[];

      AppLogging.bootstrap(
        isReleaseMode: true,
        enableVerboseLogs: true,
        sink: lines.add,
      );

      final logger = Logger('policy.release.verbose');
      logger.fine('fine-message');
      logger.warning('warn-message');

      await Future<void>.delayed(Duration.zero);

      final output = lines.join('\n');
      expect(output, contains('FINE policy.release.verbose: fine-message'));
      expect(output, contains('WARNING policy.release.verbose: warn-message'));
    });
  });
}
