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
      child: child,
    );
  }
}

// ---------- Helpers ----------
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
