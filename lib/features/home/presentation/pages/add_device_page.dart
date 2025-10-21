import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oshmobile/core/common/widgets/colored_divider.dart';
import 'package:oshmobile/core/theme/text_styles.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/home/presentation/widgets/add_device/device_form_field.dart';
import 'package:oshmobile/generated/l10n.dart';

class AddDevicePage extends StatefulWidget {
  static CupertinoPageRoute route() => CupertinoPageRoute(builder: (context) => const AddDevicePage());

  const AddDevicePage({super.key});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> with WidgetsBindingObserver {
  final _serialCtrl = TextEditingController();
  final _secureCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
    formats: [BarcodeFormat.qrCode],
  );
  bool _handledScan = false; // prevent double pop

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
    if (state == AppLifecycleState.paused) {
      _scanner.stop();
    } else if (state == AppLifecycleState.resumed) {
      _scanner.start();
    }
  }

  void _onScan(BarcodeCapture capture) {
    if (_handledScan) return;
    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
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
      context.read<HomeCubit>().assignDevice(serial, sc);
    }
  }

  Future<void> _onStateChanged(BuildContext context, HomeState state) async {
    if (state is HomeAssignDone) {
      SnackBarUtils.showSuccess(context: context, content: S.of(context).Done);
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } else if (state is HomeAssignFailed) {
      SnackBarUtils.showFail(context: context, content: S.of(context).Failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).AddDevice),
      ),
      body: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocConsumer<HomeCubit, HomeState>(
            listenWhen: (previous, current) => ModalRoute.of(context)?.isCurrent ?? true,
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
                            (state is HomeLoading)
                                ? CupertinoActivityIndicator()
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
          )),
    );
  }
}
