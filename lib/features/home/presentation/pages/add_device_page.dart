import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/common/widgets/colored_divider.dart';
import 'package:oshmobile/core/theme/text_styles.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';
import 'package:oshmobile/features/device_catalog/presentation/cubit/add_device_cubit.dart';
import 'package:oshmobile/features/home/presentation/widgets/add_device/device_form_field.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/init_dependencies.dart';

class AddDevicePage extends StatefulWidget {
  static MaterialPageRoute<void> route() => MaterialPageRoute<void>(
        settings: const RouteSettings(name: OshAnalyticsScreens.addDevice),
        builder: (_) => BlocProvider<AddDeviceCubit>(
          create: (_) => locator<AddDeviceCubit>(),
          child: const AddDevicePage(),
        ),
      );

  const AddDevicePage({super.key});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage>
    with WidgetsBindingObserver {
  final _serialCtrl = TextEditingController();
  final _secureCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: [BarcodeFormat.qrCode],
    facing: CameraFacing.back,
  );
  bool _handledScan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serialCtrl.dispose();
    _secureCtrl.dispose();
    _scanner.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (!_scanner.value.hasCameraPermission) {
      return;
    }

    if (state == AppLifecycleState.paused) {
      _scanner.stop();
    } else if (state == AppLifecycleState.resumed) {
      _scanner.start();
    }
  }

  void _onScan(BarcodeCapture capture) {
    if (_handledScan) return;
    final code =
        capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null) return;

    try {
      final obj = json.decode(code);
      if (obj is Map<String, dynamic>) {
        final serial = (obj['serial'] ?? '').toString().trim();
        final sc = (obj['secureCode'] ?? '').toString().trim();
        if (serial.isNotEmpty && sc.isNotEmpty) {
          _serialCtrl.text = serial;
          _secureCtrl.text = sc;
          _handledScan = true;
        }
      }
    } catch (_) {
      // ignore
    }
  }

  void _submitManual() {
    final serial = _serialCtrl.text.trim();
    final sc = _secureCtrl.text.trim();

    if (_formKey.currentState!.validate()) {
      context.read<AddDeviceCubit>().assignDevice(serial, sc);
    }
  }

  Future<void> _onStateChanged(
      BuildContext context, AddDeviceState state) async {
    if (state.status == AddDeviceStatus.success) {
      SnackBarUtils.showSuccess(context: context, content: S.of(context).Done);
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } else if (state.status == AddDeviceStatus.failure) {
      SnackBarUtils.showFail(
        context: context,
        content: state.errorMessage ?? S.of(context).Failed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).AddDevice),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocConsumer<AddDeviceCubit, AddDeviceState>(
            listenWhen: (previous, current) =>
                ModalRoute.of(context)?.isCurrent ?? true,
            listener: (context, state) => _onStateChanged(context, state),
            builder: (context, state) {
              return Column(
                children: [
                  Text(
                    S.of(context).PointCameraToQR,
                    style: TextStyles.contentStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: MobileScanner(
                        controller: _scanner,
                        onDetect: _onScan,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const ColoredDivider(thickness: 1.5),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            DeviceFormField(
                              labelText: S.of(context).SerialNumber,
                              controller: _serialCtrl,
                            ),
                            const SizedBox(height: 20),
                            DeviceFormField(
                              labelText: S.of(context).SecureCode,
                              controller: _secureCtrl,
                            ),
                            const SizedBox(height: 30),
                            (state.status == AddDeviceStatus.submitting)
                                ? const CircularProgressIndicator()
                                : CustomElevatedButton(
                                    buttonText: S.of(context).AddDevice,
                                    onPressed: () => _submitManual(),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
