import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/common/entities/device/connection_info.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/entities/device/device_user_data.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/configuration/models/model_configuration.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/factories/unknown_config_view_model_factory.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/unknown_config_presenter.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  testWidgets('renders unknown config screen sections', (tester) async {
    final presenter = UnknownConfigPresenter(
      viewModelFactory: const UnknownConfigViewModelFactory(),
    );

    await tester.pumpWidget(
      _host(
        presenter: presenter,
        device: _device(alias: 'Living Room', sn: 'SN-1', modelId: 'Model-1'),
        bundle: _bundle(
          widgets: const <Map<String, dynamic>>[
            {
              'id': 'heatingToggle',
              'control_ids': ['heaterEnabled']
            },
          ],
          controls: const <Map<String, dynamic>>[
            {'id': 'heaterEnabled', 'path': 'heater_enabled'},
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final s = S.of(context);

    expect(find.text('Living Room'), findsOneWidget);
    expect(find.text(s.DeviceDetails), findsOneWidget);
    expect(find.text(s.UnknownMetaControls), findsOneWidget);
    expect(find.text(s.UnknownMetaWidgets), findsOneWidget);
  });

  testWidgets('degrades gracefully for partially filled device data',
      (tester) async {
    final presenter = UnknownConfigPresenter(
      viewModelFactory: const UnknownConfigViewModelFactory(),
    );

    await tester.pumpWidget(
      _host(
        presenter: presenter,
        device: _device(alias: '   ', sn: '   ', modelId: 'Fallback-Model'),
        bundle: _bundle(
          widgets: const <Map<String, dynamic>>[],
          controls: const <Map<String, dynamic>>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fallback-Model'), findsWidgets);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
  });
}

Widget _host({
  required UnknownConfigPresenter presenter,
  required Device device,
  required DeviceConfigurationBundle bundle,
}) {
  return MaterialApp(
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Builder(
      builder: (context) {
        return presenter.build(context, device, bundle);
      },
    ),
  );
}

Device _device({
  required String alias,
  required String sn,
  required String modelId,
}) {
  return Device(
    id: 'device-1',
    sn: sn,
    modelId: modelId,
    modelName: 'Model Name',
    userData: DeviceUserData(alias: alias, description: ''),
    connectionInfo: ConnectionInfo(online: true),
  );
}

DeviceConfigurationBundle _bundle({
  required List<Map<String, dynamic>> widgets,
  required List<Map<String, dynamic>> controls,
}) {
  return DeviceConfigurationBundle(
    configurationId: 'configuration-1',
    modelId: 'model-1',
    revision: 1,
    status: 'approved',
    firmwareVersion: '0.60.0',
    runtimeContractsByDomain: const <String, RuntimeContractRecord>{},
    runtimeContractsById: const <String, RuntimeContractRecord>{},
    readableDomains: const <String>{'telemetry'},
    patchableDomains: const <String>{},
    configuration: ModelConfiguration.fromJson(
      <String, dynamic>{
        'schema_version': 1,
        'integrations': {
          'oshmobile': {
            'layout': 'thermostat_basic',
            'domains': {
              'telemetry': {'contract_id': 'telemetry@1'},
            },
            'widgets': widgets,
            'controls': [
              for (final control in controls)
                {
                  'id': control['id'],
                  'title': control['id'],
                  'read': {
                    'kind': 'domain_path',
                    'domain': 'telemetry',
                    'path': control['path'],
                  },
                },
            ],
          },
        },
      },
    ),
  );
}
