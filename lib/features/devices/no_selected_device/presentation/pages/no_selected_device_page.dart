import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/generated/l10n.dart';

bool _noDeviceIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

class NoSelectedDevicePage extends StatelessWidget {
  const NoSelectedDevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.question_mark,
              size: 150.0,
              color: (_noDeviceIsDark(context)
                      ? AppPalette.textMuted
                      : const Color(0xFF64748B))
                  .withValues(alpha: 0.22),
            ),
            const SizedBox(height: 20),
            Text(
              S.of(context).NoDeviceSelected,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _noDeviceIsDark(context)
                    ? AppPalette.textSecondary
                    : const Color(0xFF475569),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
