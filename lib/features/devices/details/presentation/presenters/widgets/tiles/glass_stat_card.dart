import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

// ---------- Common glassy card wrapper ----------
class GlassStatCard extends StatelessWidget {
  const GlassStatCard(
      {super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: padding ?? const EdgeInsets.all(AppPalette.spaceLg),
      onTap: onTap,
      backgroundColor: statSurfaceColor(context),
      borderColor: statBorderColor(context),
      child: child,
    );
  }
}

// ---------- Helpers ----------
bool isDarkSurface(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color statSurfaceColor(BuildContext context) =>
    isDarkSurface(context) ? AppPalette.surfaceRaised : Colors.white;

Color statSurfaceAltColor(BuildContext context) => isDarkSurface(context)
    ? AppPalette.surfaceAlt
    : const Color(0xFFF3F4F6);

Color statBorderColor(BuildContext context) => isDarkSurface(context)
    ? AppPalette.borderSoft
    : const Color(0x1A0F172A);

Color statTitleColor(BuildContext context) => isDarkSurface(context)
    ? AppPalette.textSecondary
    : const Color(0xFF475569);

Color statValueColor(BuildContext context) =>
    isDarkSurface(context) ? AppPalette.textPrimary : const Color(0xFF0F172A);

Color statMutedColor(BuildContext context) =>
    isDarkSurface(context) ? AppPalette.textMuted : const Color(0xFF6B7280);

num? asNum(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

String fmtNum(num? v, {int decimalsIfNeeded = 1}) {
  if (v == null) return '—';
  return (v % 1 == 0)
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(decimalsIfNeeded);
}

dynamic readBind(Map<String, dynamic> data, String bind) {
  if (data.containsKey(bind)) return data[bind];

  dynamic cur = data;
  for (final part in bind.split('.')) {
    if (cur is! Map) return null;
    if (!cur.containsKey(part)) return null;
    cur = cur[part];
  }
  return cur;
}
