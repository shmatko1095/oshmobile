import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_heating_indicator.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  testWidgets('plays two pulses and settles at the static active state',
      (tester) async {
    await _pumpIndicator(tester, active: true);

    final tween = tester.widget<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    );
    expect(tween.duration, const Duration(milliseconds: 1380));

    await tester.pump(const Duration(milliseconds: 480));
    _expectMotion(tester, opacity: 0.88, scale: 1.06);

    await tester.pump(const Duration(milliseconds: 300));
    _expectMotion(tester, opacity: 1, scale: 1);

    await tester.pump(const Duration(milliseconds: 300));
    _expectMotion(tester, opacity: 0.88, scale: 1.06);

    await tester.pump(const Duration(milliseconds: 300));
    _expectMotion(tester, opacity: 1, scale: 1);
  });

  testWidgets('fades the fire out when heating switches off', (tester) async {
    await _pumpIndicator(tester, active: true);
    await tester.pumpAndSettle();

    await _pumpIndicator(tester, active: false);

    expect(
      find.byKey(const ValueKey('thermostat-heating-fire-image')),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('thermostat-heating-fire-image')),
      findsNothing,
    );
  });

  testWidgets('disables heating motion when reduced motion is requested',
      (tester) async {
    await _pumpIndicator(
      tester,
      active: true,
      disableAnimations: true,
    );
    await tester.pump();

    final tween = tester.widget<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    );
    expect(tween.duration, Duration.zero);
    _expectMotion(tester, opacity: 1, scale: 1);
  });
}

Future<void> _pumpIndicator(
  WidgetTester tester, {
  required bool? active,
  bool disableAnimations = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(
            child: ThermostatHeatingIndicator(
              active: active,
              selected: true,
              ultraCompact: false,
            ),
          ),
        ),
      ),
    ),
  );
}

void _expectMotion(
  WidgetTester tester, {
  required double opacity,
  required double scale,
}) {
  final opacityWidget = tester.widget<Opacity>(
    find.byKey(const ValueKey('thermostat-heating-motion-opacity')),
  );
  final scaleWidget = tester.widget<Transform>(
    find.byKey(const ValueKey('thermostat-heating-motion-scale')),
  );

  expect(opacityWidget.opacity, closeTo(opacity, 0.001));
  expect(scaleWidget.transform.getMaxScaleOnAxis(), closeTo(scale, 0.001));
}
