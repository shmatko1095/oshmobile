import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

class HistoryLineChart extends StatelessWidget {
  const HistoryLineChart({
    super.key,
    required this.values,
    this.color = AppPalette.accentPrimary,
    this.strokeWidth = 2.0,
    this.fill = true,
    this.showGrid = true,
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool fill;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HistoryLineChartPainter(
        values: values,
        color: color,
        strokeWidth: strokeWidth,
        fill: fill,
        showGrid: showGrid,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _HistoryLineChartPainter extends CustomPainter {
  const _HistoryLineChartPainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    required this.fill,
    required this.showGrid,
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool fill;
  final bool showGrid;

  @override
  void paint(Canvas canvas, Size size) {
    final safeWidth = size.width <= 0 ? 1.0 : size.width;
    final safeHeight = size.height <= 0 ? 1.0 : size.height;
    final rect = Offset.zero & Size(safeWidth, safeHeight);

    if (showGrid) {
      final gridPaint = Paint()
        ..color = AppPalette.separator
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (var i = 1; i <= 3; i++) {
        final y = rect.top + rect.height * (i / 4);
        canvas.drawLine(
          Offset(rect.left, y),
          Offset(rect.right, y),
          gridPaint,
        );
      }
    }

    if (values.isEmpty) {
      return;
    }

    if (values.length == 1) {
      final centerY = rect.center.dy;
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(rect.left, centerY),
        Offset(rect.right, centerY),
        paint,
      );
      return;
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final span =
        (maxValue - minValue).abs() < 0.000001 ? 1.0 : (maxValue - minValue);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final dx = rect.left + (rect.width * i / (values.length - 1));
      final normalized = (values[i] - minValue) / span;
      final dy = rect.bottom - normalized * rect.height;
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: 0.15),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _HistoryLineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.fill != fill ||
        oldDelegate.showGrid != showGrid;
  }
}
