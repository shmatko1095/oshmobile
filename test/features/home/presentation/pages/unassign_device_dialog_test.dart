import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/theme/theme.dart';
import 'package:oshmobile/features/home/presentation/pages/unassign_device_dialog.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  testWidgets('renders styled material dialog content in dark theme',
      (tester) async {
    const deviceName = 'Very long thermostat name for the hallway controller';

    await _pumpDialogHarness(
      tester,
      theme: AppTheme.darkTheme,
      deviceName: deviceName,
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Remove device?'), findsOneWidget);
    expect(
      find.text(
        'The device $deviceName will be removed from your list. '
        'You can re-add it anytime by scanning the QR code again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Remove device'), findsOneWidget);

    final surface = tester.widget<Material>(
      find.byKey(const ValueKey('unassign_device_dialog_surface')),
    );
    expect(surface.color, AppPalette.surfaceRaised);
  });

  testWidgets('cancel, barrier tap, and system back dismiss without approval',
      (tester) async {
    await _pumpDialogHarness(tester, theme: AppTheme.lightTheme);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('result:false'), findsOneWidget);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('result:null'), findsOneWidget);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('result:null'), findsOneWidget);
  });

  testWidgets('remove action closes dialog with approval', (tester) async {
    await _pumpDialogHarness(tester, theme: AppTheme.lightTheme);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove device'));
    await tester.pumpAndSettle();

    expect(find.text('result:true'), findsOneWidget);
  });
}

Future<void> _pumpDialogHarness(
  WidgetTester tester, {
  required ThemeData theme,
  String deviceName = 'Living room thermostat',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: _DialogHarness(deviceName: deviceName),
    ),
  );

  await tester.pump();
}

class _DialogHarness extends StatefulWidget {
  const _DialogHarness({
    required this.deviceName,
  });

  final String deviceName;

  @override
  State<_DialogHarness> createState() => _DialogHarnessState();
}

class _DialogHarnessState extends State<_DialogHarness> {
  bool? _lastResult;
  bool _hasResult = false;

  Future<void> _openDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => UnassignDeviceDialog(deviceName: widget.deviceName),
    );
    if (!mounted) return;
    setState(() {
      _hasResult = true;
      _lastResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: TextButton(
              onPressed: _openDialog,
              child: const Text('open'),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              _hasResult ? 'result:${_lastResult?.toString() ?? 'null'}' : '-',
            ),
          ),
        ],
      ),
    );
  }
}
