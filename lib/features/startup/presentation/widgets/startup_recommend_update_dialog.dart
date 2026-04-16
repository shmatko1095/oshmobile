import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/widgets/app_button.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/generated/l10n.dart';

Future<void> showStartupRecommendUpdateDialog({
  required BuildContext context,
  required VoidCallback onUpdateNow,
  required VoidCallback onLater,
}) {
  final s = S.of(context);

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppPalette.spaceXl,
          vertical: AppPalette.spaceXl,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Semantics(
          label: s.startupUpdateRecommendSemantics,
          child: AppSolidCard(
            backgroundColor: Theme.of(context).cardColor,
            borderColor: Theme.of(context).brightness == Brightness.dark
                ? AppPalette.borderSoft
                : AppPalette.lightBorder,
            padding: const EdgeInsets.all(AppPalette.spaceXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppPalette.accentPrimary.withValues(alpha: 0.14),
                        borderRadius:
                            BorderRadius.circular(AppPalette.radiusMd),
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: AppPalette.accentPrimary,
                      ),
                    ),
                    const SizedBox(width: AppPalette.spaceLg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.startupUpdateRecommendTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppPalette.spaceSm),
                          Text(
                            s.startupUpdateRecommendSubtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppPalette.spaceXl),
                AppButton(
                  text: s.startupUpdateNow,
                  onPressed: onUpdateNow,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                ),
                const SizedBox(height: AppPalette.spaceSm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onLater,
                    child: Text(s.startupUpdateLater),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
