import 'package:flutter/material.dart';
import 'package:oshmobile/generated/l10n.dart';

class UnknownDevicePage extends StatelessWidget {
  const UnknownDevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_rounded,
              size: 150.0,
              color: Colors.red.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 20),
            Text(
              S.of(context).UnknownDeviceType,
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
