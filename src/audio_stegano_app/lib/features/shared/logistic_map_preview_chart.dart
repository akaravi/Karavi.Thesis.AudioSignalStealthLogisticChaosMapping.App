import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/stego/audio_watermarking.dart';

/// Live preview of the logistic chaos sequence for current [r] and [x0].
class LogisticMapPreviewChart extends StatelessWidget {
  final double r;
  final double x0;
  final String? caption;

  const LogisticMapPreviewChart({
    super.key,
    required this.r,
    required this.x0,
    this.caption,
  });

  static const int sampleCount = 120;
  static const double chartHeight = 168;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (caption != null && caption!.isNotEmpty) ...[
          Text(
            caption!,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: scheme.surfaceContainerHighest,
            child: SizedBox(
              height: chartHeight,
              width: double.infinity,
              child: CustomPaint(
                painter: _LogisticMapPreviewPainter(
                  r: r,
                  x0: x0,
                  lineColor: scheme.primary,
                  gridColor: scheme.outlineVariant,
                  thresholdColor: scheme.secondary.withValues(alpha: 0.85),
                  labelColor: scheme.onSurfaceVariant,
                  labelStyle: textTheme.labelSmall,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogisticMapPreviewPainter extends CustomPainter {
  final double r;
  final double x0;
  final Color lineColor;
  final Color gridColor;
  final Color thresholdColor;
  final Color labelColor;
  final TextStyle? labelStyle;

  static const double _padL = 44;
  static const double _padR = 8;
  static const double _padT = 8;
  static const double _padB = 26;

  _LogisticMapPreviewPainter({
    required this.r,
    required this.x0,
    required this.lineColor,
    required this.gridColor,
    required this.thresholdColor,
    required this.labelColor,
    this.labelStyle,
  });

  TextStyle get _axisTextStyle =>
      (labelStyle ?? const TextStyle(fontSize: 10)).copyWith(
        color: labelColor,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static String _formatY(double value) {
    final a = value.abs();
    if (a >= 10) return value.toStringAsFixed(1);
    if (a >= 1) return value.toStringAsFixed(2);
    return value.toStringAsFixed(3);
  }

  void _paintLabel(
    Canvas canvas,
    String text, {
    required double x,
    required double y,
    required TextAlign align,
    required double maxWidth,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: _axisTextStyle),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    var left = x;
    if (align == TextAlign.right) {
      left = x - tp.width;
    } else if (align == TextAlign.center) {
      left = x - tp.width / 2;
    }
    tp.paint(canvas, Offset(left, y - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - _padL - _padR;
    final plotH = size.height - _padT - _padB;
    if (plotW <= 1 || plotH <= 1) return;

    final seq = LogisticMap.sequence(
      length: LogisticMapPreviewChart.sampleCount,
      x0: x0,
      r: r,
    );
    if (seq.isEmpty) return;

    var yMin = 1.0;
    var yMax = 0.0;
    for (final v in seq) {
      if (v < yMin) yMin = v;
      if (v > yMax) yMax = v;
    }
    final span = (yMax - yMin).abs();
    if (span < 1e-9) {
      yMin -= 0.05;
      yMax += 0.05;
    } else {
      final margin = span * 0.08;
      yMin -= margin;
      yMax += margin;
    }

    double mapY(double value) =>
        _padT + plotH * (1.0 - (value - yMin) / (yMax - yMin));

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (final level in [0.0, 0.5, 1.0]) {
      final y = mapY(level.clamp(yMin, yMax));
      canvas.drawLine(Offset(_padL, y), Offset(_padL + plotW, y), gridPaint);
    }

    var sum = 0.0;
    for (final v in seq) {
      sum += v;
    }
    final threshold = sum / seq.length;
    final threshY = mapY(threshold.clamp(yMin, yMax));
    final dashPaint = Paint()
      ..color = thresholdColor
      ..strokeWidth = 1.25
      ..style = PaintingStyle.stroke;
    _drawDashedLine(
      canvas,
      Offset(_padL, threshY),
      Offset(_padL + plotW, threshY),
      dashPaint,
    );

    final path = ui.Path();
    for (var i = 0; i < seq.length; i++) {
      final x = _padL + (i / (seq.length - 1)) * plotW;
      final y = mapY(seq[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.25
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    final yMid = (yMin + yMax) / 2;
    for (final value in [yMax, yMid, yMin]) {
      _paintLabel(
        canvas,
        _formatY(value),
        x: _padL - 6,
        y: mapY(value),
        align: TextAlign.right,
        maxWidth: _padL - 8,
      );
    }

    final n = LogisticMapPreviewChart.sampleCount;
    final xTicks = <(int step, double x)>[
      (1, _padL),
      (n ~/ 2, _padL + plotW / 2),
      (n, _padL + plotW),
    ];
    for (final (step, x) in xTicks) {
      _paintLabel(
        canvas,
        '$step',
        x: x,
        y: _padT + plotH + 4,
        align: TextAlign.center,
        maxWidth: 48,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    var dist = 0.0;
    var draw = true;
    while (dist < len) {
      final seg = draw ? dash : gap;
      final t1 = dist / len;
      final t2 = ((dist + seg).clamp(0.0, len)) / len;
      if (draw) {
        canvas.drawLine(
          Offset(a.dx + dx * t1, a.dy + dy * t1),
          Offset(a.dx + dx * t2, a.dy + dy * t2),
          paint,
        );
      }
      dist += seg;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(covariant _LogisticMapPreviewPainter old) =>
      old.r != r ||
      old.x0 != x0 ||
      old.lineColor != lineColor ||
      old.gridColor != gridColor ||
      old.thresholdColor != thresholdColor ||
      old.labelColor != labelColor ||
      old.labelStyle != labelStyle;
}
