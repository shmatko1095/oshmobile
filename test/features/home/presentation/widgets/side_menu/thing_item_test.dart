import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/theme/theme.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/thing_item.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  testWidgets('does not render overflow menu action anymore', (tester) async {
    await _pumpThingItem(tester);

    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
  });

  testWidgets('swipe to remove opens same confirm dialog', (tester) async {
    await _pumpThingItem(tester);

    await tester.drag(
      find.byKey(const ValueKey('drawer_device_device-1')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Remove device?'), findsOneWidget);
    expect(find.text('Remove device'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('drawer_device_device-1')), findsOneWidget);
  });
}

Future<void> _pumpThingItem(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: const Scaffold(
        body: Center(
          child: SizedBox(
            width: 420,
            child: ThingItem(
              id: 'device-1',
              name: 'Living room thermostat',
              room: 'Living room',
              online: true,
              selected: false,
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pump();
}
