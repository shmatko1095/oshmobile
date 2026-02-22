import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/home/presentation/pages/add_device_page.dart';
import 'package:oshmobile/generated/l10n.dart';

class AddDeviceButton extends StatelessWidget {
  const AddDeviceButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AppSolidCard(
        padding: EdgeInsets.zero,
        backgroundColor: AppPalette.surface,
        child: ListTile(
          leading: const Icon(Icons.add, color: AppPalette.accentPrimary),
          title: Text(S.of(context).AddDevice),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppPalette.textMuted,
          ),
          onTap: () => Navigator.push(context, AddDevicePage.route()),
        ),
      ),
    );
  }
}
