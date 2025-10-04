import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/auth/presentation/widgets/elevated_button.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/generated/l10n.dart';

class RenameDevicePage extends StatefulWidget {
  final String deviceId;
  final String name;
  final String room;

  static CupertinoPageRoute route(
          {required String deviceId,
          required String name,
          required String room}) =>
      CupertinoPageRoute(
          builder: (context) => RenameDevicePage(
                deviceId: deviceId,
                name: name,
                room: room,
              ));

  const RenameDevicePage({
    super.key,
    required this.deviceId,
    required this.name,
    required this.room,
  });

  @override
  State<RenameDevicePage> createState() => _RenameDevicePageState();
}

class _RenameDevicePageState extends State<RenameDevicePage> {
  final _aliasCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _aliasCtrl.text = widget.name;
    _descriptionCtrl.text = widget.room;
    super.initState();
  }

  @override
  void dispose() {
    _aliasCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final alias = _aliasCtrl.text.trim();
    final desc = _descriptionCtrl.text.trim();

    if (_formKey.currentState!.validate()) {
      context.read<HomeCubit>().updateDeviceUserData(
            widget.deviceId,
            alias,
            desc,
          );
    }
  }

  Future<void> _onStateChanged(BuildContext context, HomeState state) async {
    if (state is HomeUpdateDeviceUserDataDone) {
      SnackBarUtils.showSuccess(context: context, content: S.of(context).Done);
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } else if (state is HomeUpdateDeviceUserDataFailed) {
      SnackBarUtils.showFail(context: context, content: S.of(context).Failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).DeviceEditTitle),
      ),
      body: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocConsumer<HomeCubit, HomeState>(
            listenWhen: (previous, current) =>
                ModalRoute.of(context)?.isCurrent ?? true,
            listener: (context, state) => _onStateChanged(context, state),
            builder: (context, state) {
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
                            (state is HomeLoading)
                                ? CupertinoActivityIndicator()
                                : CustomElevatedButton(
                                    buttonText: S.of(context).OK,
                                    onPressed: () => _submit(),
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
