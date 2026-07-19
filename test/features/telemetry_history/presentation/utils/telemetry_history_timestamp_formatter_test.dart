import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_range.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_window.dart';
import 'package:oshmobile/features/telemetry_history/presentation/utils/telemetry_history_timestamp_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US');
    await initializeDateFormatting('uk_UA');
  });

  test('day tooltip shows the Europe/Stockholm local date and time', () {
    final label = telemetryHistoryTooltipTimestampLabel(
      timestamp: DateTime.utc(2026, 7, 17),
      window: _window(TelemetryHistoryRange.day),
      localeTag: 'en_US',
      localize: (_) => DateTime(2026, 7, 17, 2),
    );

    expect(label, '7/17/2026 02:00');
  });

  test('week and month tooltips show only the America/New_York date', () {
    for (final range in <TelemetryHistoryRange>[
      TelemetryHistoryRange.week,
      TelemetryHistoryRange.month,
    ]) {
      final label = telemetryHistoryTooltipTimestampLabel(
        timestamp: DateTime.utc(2026, 7, 17),
        window: _window(range),
        localeTag: 'en_US',
        localize: (_) => DateTime(2026, 7, 16, 20),
      );

      expect(label, '7/16/2026');
    }
  });

  test('year tooltip shows the localized month and year', () {
    final label = telemetryHistoryTooltipTimestampLabel(
      timestamp: DateTime.utc(2026, 7, 1),
      window: _window(TelemetryHistoryRange.year),
      localeTag: 'uk_UA',
      localize: (_) => DateTime(2026, 7, 1),
    );

    expect(label, contains('липень'));
    expect(label, contains('2026'));
    expect(label, isNot(contains(':')));
  });

  test('custom tooltip detail follows the selected calendar duration', () {
    final oneDay = TelemetryHistoryWindow.custom(
      startLocal: DateTime(2026, 7, 17),
      endInclusiveLocal: DateTime(2026, 7, 17),
    );
    final oneWeek = TelemetryHistoryWindow.custom(
      startLocal: DateTime(2026, 7, 13),
      endInclusiveLocal: DateTime(2026, 7, 19),
    );
    final twoMonths = TelemetryHistoryWindow.custom(
      startLocal: DateTime(2026, 6, 1),
      endInclusiveLocal: DateTime(2026, 7, 31),
    );
    final timestamp = DateTime.utc(2026, 7, 17);
    DateTime localize(DateTime _) => DateTime(2026, 7, 17, 2);

    expect(
      telemetryHistoryTooltipTimestampLabel(
        timestamp: timestamp,
        window: oneDay,
        localeTag: 'en_US',
        localize: localize,
      ),
      '7/17/2026 02:00',
    );
    expect(
      telemetryHistoryTooltipTimestampLabel(
        timestamp: timestamp,
        window: oneWeek,
        localeTag: 'en_US',
        localize: localize,
      ),
      '7/17/2026',
    );
    expect(
      telemetryHistoryTooltipTimestampLabel(
        timestamp: timestamp,
        window: twoMonths,
        localeTag: 'en_US',
        localize: localize,
      ),
      'July 2026',
    );
  });

  test('day tooltip preserves the Europe/Stockholm DST jump', () {
    final window = _window(TelemetryHistoryRange.day);
    final before = telemetryHistoryTooltipTimestampLabel(
      timestamp: DateTime.utc(2026, 3, 29),
      window: window,
      localeTag: 'en_US',
      localize: (_) => DateTime(2026, 3, 29, 1),
    );
    final after = telemetryHistoryTooltipTimestampLabel(
      timestamp: DateTime.utc(2026, 3, 29, 1),
      window: window,
      localeTag: 'en_US',
      localize: (_) => DateTime(2026, 3, 29, 3),
    );

    expect(before, endsWith('01:00'));
    expect(after, endsWith('03:00'));
  });
}

TelemetryHistoryWindow _window(TelemetryHistoryRange range) {
  return TelemetryHistoryWindow.containing(
    range: range,
    anchorLocal: DateTime(2026, 7, 17),
  );
}
