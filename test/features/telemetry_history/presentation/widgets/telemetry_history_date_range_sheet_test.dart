import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_retention_policy.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_range.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_window.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/show_telemetry_history_date_range_sheet.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/telemetry_history_date_range_sheet.dart';
import 'package:oshmobile/generated/l10n.dart';

Widget _localizedApp({
  required Widget home,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    locale: locale,
    theme: ThemeData(brightness: brightness),
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: home,
  );
}

void main() {
  testWidgets('opens at high sheet height and returns the initial day range',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime(2026, 7, 17, 14, 30);
    final window = TelemetryHistoryWindow.current(
      range: TelemetryHistoryRange.day,
      nowLocal: now,
    );
    DateTimeRange? result;

    await tester.pumpWidget(
      _localizedApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await showTelemetryHistoryDateRangeSheet(
                    context: context,
                    window: window,
                    nowLocal: now,
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final sheet = find.byKey(
      const ValueKey('telemetry-history-date-range-sheet'),
    );
    expect(sheet, findsOneWidget);
    final sheetHeight = tester.getSize(sheet).height;
    expect(sheetHeight, greaterThanOrEqualTo(800 * 0.85));
    expect(sheetHeight, lessThanOrEqualTo(800));
    final calendar = tester.widget<CalendarDatePicker2>(
      find.byKey(const ValueKey('telemetry-history-date-range-calendar')),
    );
    expect(calendar.config.lastDate, DateTime(2026, 7, 17));
    expect(
      calendar.config.firstDate,
      DateUtils.dateOnly(
        now.subtract(const TelemetryHistoryRetentionPolicy().maxQueryDuration),
      ),
    );
    final apply = tester.widget<FilledButton>(
      find.byKey(const ValueKey('telemetry-history-date-range-apply')),
    );
    expect(apply.onPressed, isNotNull);

    await tester.tap(
      find.byKey(const ValueKey('telemetry-history-date-range-apply')),
    );
    await tester.pumpAndSettle();

    expect(result?.start, DateTime(2026, 7, 17));
    expect(result?.end, DateTime(2026, 7, 17));
  });

  testWidgets('selected day month and year labels contrast with selection',
      (tester) async {
    final now = DateTime(2026, 7, 17, 14, 30);
    final window = TelemetryHistoryWindow.current(
      range: TelemetryHistoryRange.day,
      nowLocal: now,
    );

    await tester.pumpWidget(
      _localizedApp(
        brightness: Brightness.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTelemetryHistoryDateRangeSheet(
                context: context,
                window: window,
                nowLocal: now,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final calendar = tester.widget<CalendarDatePicker2>(
      find.byKey(const ValueKey('telemetry-history-date-range-calendar')),
    );
    expect(calendar.config.selectedDayHighlightColor, AppPalette.accentPrimary);
    expect(calendar.config.selectedDayTextStyle?.color, AppPalette.white);
    expect(calendar.config.selectedMonthTextStyle?.color, AppPalette.white);
    expect(calendar.config.selectedYearTextStyle?.color, AppPalette.white);
  });

  testWidgets('cancel closes the sheet without returning a range',
      (tester) async {
    final now = DateTime(2026, 7, 17, 14, 30);
    final window = TelemetryHistoryWindow.current(
      range: TelemetryHistoryRange.day,
      nowLocal: now,
    );
    DateTimeRange? result;
    var completed = false;

    await tester.pumpWidget(
      _localizedApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await showTelemetryHistoryDateRangeSheet(
                    context: context,
                    window: window,
                    nowLocal: now,
                  );
                  completed = true;
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('telemetry-history-date-range-cancel')),
    );
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
    expect(
      find.byKey(const ValueKey('telemetry-history-date-range-sheet')),
      findsNothing,
    );
  });

  testWidgets('announces an overlong range and disables apply', (tester) async {
    final now = DateTime(2026, 7, 17, 14, 30);
    final firstDate = DateUtils.dateOnly(
      now.subtract(const TelemetryHistoryRetentionPolicy().maxQueryDuration),
    );

    await tester.pumpWidget(
      _localizedApp(
        home: TelemetryHistoryDateRangeSheet(
          nowLocal: now,
          firstDateLocal: firstDate,
          displayedMonthLocal: DateTime(2026, 7),
          retentionPolicy: const TelemetryHistoryRetentionPolicy(),
          initialRange: DateTimeRange(
            start: firstDate,
            end: DateTime(2026, 7, 17),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('telemetry-history-date-range-error')),
      findsOneWidget,
    );
    expect(find.text('The range cannot exceed 370 days.'), findsOneWidget);
    final apply = tester.widget<FilledButton>(
      find.byKey(const ValueKey('telemetry-history-date-range-apply')),
    );
    expect(apply.onPressed, isNull);
  });

  testWidgets('normalizes reverse day selection and enables apply',
      (tester) async {
    final now = DateTime(2026, 7, 17, 14, 30);

    await tester.pumpWidget(
      _localizedApp(
        home: TelemetryHistoryDateRangeSheet(
          nowLocal: now,
          firstDateLocal: DateTime(2025, 7, 12),
          displayedMonthLocal: DateTime(2026, 7),
          retentionPolicy: const TelemetryHistoryRetentionPolicy(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('12'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(
              const ValueKey('telemetry-history-date-range-apply'),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('10'));
    await tester.pump();

    expect(find.text('10–12 July 2026'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(
              const ValueKey('telemetry-history-date-range-apply'),
            ),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('formats the selected range in Ukrainian', (tester) async {
    final now = DateTime(2026, 7, 20, 12);

    await tester.pumpWidget(
      _localizedApp(
        locale: const Locale('uk'),
        home: TelemetryHistoryDateRangeSheet(
          nowLocal: now,
          firstDateLocal: DateTime(2025, 7, 15),
          displayedMonthLocal: DateTime(2026, 7),
          retentionPolicy: const TelemetryHistoryRetentionPolicy(),
          initialRange: DateTimeRange(
            start: DateTime(2026, 7, 13),
            end: DateTime(2026, 7, 19),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Оберіть діапазон дат'), findsOneWidget);
    expect(find.text('13–19 липня 2026'), findsOneWidget);
  });
}
