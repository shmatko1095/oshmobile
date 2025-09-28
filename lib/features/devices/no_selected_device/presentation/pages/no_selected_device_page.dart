import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/generated/l10n.dart';

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
              color: AppPalette.blue.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 20),
            Text(
              S.of(context).NoDeviceSelected,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
