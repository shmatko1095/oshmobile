import 'package:flutter/material.dart';

// ---------- Common glassy card wrapper ----------
class GlassStatCard extends StatelessWidget {
  const GlassStatCard({super.key, required this.child, this.onTap, this.padding});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final content = Ink(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
    return onTap == null
        ? Card(
            color: Colors.transparent,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: content,
          )
        : InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Card(
              color: Colors.transparent,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: content,
            ),
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
  return (v % 1 == 0) ? v.toStringAsFixed(0) : v.toStringAsFixed(decimalsIfNeeded);
}
