import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';
import 'package:oshmobile/features/device_catalog/presentation/cubit/device_catalog_cubit.dart';
import 'package:oshmobile/features/device_management/presentation/cubit/device_management_cubit.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/init_dependencies.dart';

class RenameDevicePage extends StatefulWidget {
  final String deviceId;

  static MaterialPageRoute<void> route({
    required String deviceId,
  }) =>
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: OshAnalyticsScreens.renameDevice),
        builder: (_) => BlocProvider<DeviceManagementCubit>(
          create: (_) => locator<DeviceManagementCubit>(),
          child: RenameDevicePage(deviceId: deviceId),
        ),
      );

  const RenameDevicePage({
    super.key,
    required this.deviceId,
  });

  @override
  State<RenameDevicePage> createState() => _RenameDevicePageState();
}

class _RenameDevicePageState extends State<RenameDevicePage> {
  final _aliasCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final String _serial;
  late final String _initialAlias;
  late final String _initialDescription;

  String _norm(String? value) =>
      (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');

  bool get _canSave =>
      _norm(_aliasCtrl.text) != _initialAlias ||
      _norm(_descriptionCtrl.text) != _initialDescription;

  @override
  void initState() {
    super.initState();
    final device = context.read<DeviceCatalogCubit>().getById(widget.deviceId);
    _serial = device?.sn ?? '';
    _initialAlias = _norm(device?.userData.alias);
    _initialDescription = _norm(device?.userData.description);

    _aliasCtrl.text = device?.userData.alias ?? '';
    _descriptionCtrl.text = device?.userData.description ?? '';

    _aliasCtrl.addListener(() => setState(() {}));
    _descriptionCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _aliasCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSave || _serial.isEmpty) return;
    if (_formKey.currentState!.validate()) {
      context.read<DeviceManagementCubit>().renameDevice(
            serial: _serial,
            alias: _norm(_aliasCtrl.text),
            description: _norm(_descriptionCtrl.text),
          );
    }
  }

  Future<void> _onStateChanged(
    BuildContext context,
    DeviceManagementState state,
  ) async {
    if (state.action != DeviceManagementAction.rename) return;

    if (state.status == DeviceManagementStatus.success) {
      SnackBarUtils.showSuccess(context: context, content: S.of(context).Done);
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } else if (state.status == DeviceManagementStatus.failure) {
      SnackBarUtils.showFail(
        context: context,
        content: state.errorMessage ?? S.of(context).Failed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = context.select<DeviceCatalogCubit, Device?>(
      (cubit) => cubit.getById(widget.deviceId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).DeviceEditTitle),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocConsumer<DeviceManagementCubit, DeviceManagementState>(
            listenWhen: (previous, current) =>
                ModalRoute.of(context)?.isCurrent ?? true,
            listener: _onStateChanged,
            builder: (context, state) {
              if (device == null && _serial.isEmpty) {
                return Center(
                  child: Text(S.of(context).NoDeviceSelected),
                );
              }

              final isLoading =
                  state.status == DeviceManagementStatus.submitting;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _aliasCtrl,
                              decoration: InputDecoration(
                                labelText: S.of(context).Name,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _descriptionCtrl,
                              decoration: InputDecoration(
                                labelText: S.of(context).Room,
                              ),
                            ),
                            const SizedBox(height: 30),
                            if (isLoading)
                              const CircularProgressIndicator()
                            else
                              CustomElevatedButton(
                                buttonText: S.of(context).OK,
                                onPressed: _canSave ? _submit : null,
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
