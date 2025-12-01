import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';
import 'package:oshmobile/features/ble_provisioning/presentation/cubit/ble_provisioning_cubit.dart';
import 'package:oshmobile/generated/l10n.dart';

class WifiPasswordStep extends StatefulWidget {
  final bool isConnecting;

  const WifiPasswordStep({
    super.key,
    required this.isConnecting,
  });

  @override
  State<WifiPasswordStep> createState() => _WifiPasswordStepState();
}

class _WifiPasswordStepState extends State<WifiPasswordStep> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onConnect() {
    final pass = _controller.text.trim();
    if (pass.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<BleProvisioningCubit>().connectWifi(pass);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            obscureText: _obscure,
            enabled: !widget.isConnecting,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onConnect(),
            decoration: InputDecoration(
              labelText: S.of(context).Password,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() => _obscure = !_obscure);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, child) {
              final isNotEmpty = value.text.trim().isNotEmpty;

              return AppButton(
                onPressed: (isNotEmpty && !widget.isConnecting) ? _onConnect : null,
                text: S.of(context).Connect,
                isLoading: widget.isConnecting,
              );
            },
          ),
        ],
      ),
    );
  }
}
