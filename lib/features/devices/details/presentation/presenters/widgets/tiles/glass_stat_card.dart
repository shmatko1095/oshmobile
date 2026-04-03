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
    isDarkSurface(context) ? AppPalette.surfaceRaised : AppPalette.white;

Color statSurfaceAltColor(BuildContext context) => isDarkSurface(context)
    ? AppPalette.surfaceAlt
    : AppPalette.lightSurfaceSubtle;

Color statBorderColor(BuildContext context) =>
    isDarkSurface(context) ? AppPalette.borderSoft : AppPalette.lightBorder;

Color statTitleColor(BuildContext context) => isDarkSurface(context)
    ? AppPalette.textSecondary
    : AppPalette.lightTextSecondary;

Color statValueColor(BuildContext context) => isDarkSurface(context)
    ? AppPalette.textPrimary
    : AppPalette.lightTextPrimary;

Color statMutedColor(BuildContext context) => isDarkSurface(context)
    ? AppPalette.textMuted
    : AppPalette.lightTextDisabled;

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
