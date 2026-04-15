import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

class StartupLoader extends StatelessWidget {
  const StartupLoader({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.canvas,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: AppPalette.spaceLg),
                Text(
                  message!,
                  style: const TextStyle(color: AppPalette.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
