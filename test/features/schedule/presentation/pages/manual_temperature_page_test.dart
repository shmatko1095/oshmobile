import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/presentation/pages/manual_temperature_page.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  testWidgets('temperature roller omits the unit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: ManualTemperaturePage(
          initial: const ScheduleSetpoint.temperature(21),
          title: 'Setpoint',
          onSave: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final picker = find.byType(CupertinoPicker);
    expect(
      find.descendant(of: picker, matching: find.text('21.0')),
      findsWidgets,
    );
    expect(
      find.descendant(of: picker, matching: find.text('21.0°C')),
      findsNothing,
    );
  });

  testWidgets('ON/OFF picker exposes the selected setpoint to semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: ManualTemperaturePage(
          initial: const ScheduleSetpoint.off(),
          title: 'Setpoint',
          supportedSetpointKinds: const <ScheduleSetpointKind>{
            ScheduleSetpointKind.temperature,
            ScheduleSetpointKind.on,
            ScheduleSetpointKind.off,
          },
          onSave: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final picker = find.bySemanticsLabel('Schedule setpoint picker');
    expect(picker, findsOneWidget);
    expect(tester.getSemantics(picker).value, 'OFF');

    await tester.drag(find.byType(CupertinoPicker), const Offset(0, -10000));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(picker).value, 'ON');
    semantics.dispose();
  });
}
