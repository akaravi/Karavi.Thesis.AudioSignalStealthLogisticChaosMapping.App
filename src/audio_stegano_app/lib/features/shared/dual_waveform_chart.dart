import 'package:flutter/material.dart';

/// Overlays cover (original) and stego waveforms with distinct theme colors.
class DualWaveformChart extends StatelessWidget {
  final List<double> coverEnvelope;
  final List<double> stegoEnvelope;
  final String coverLabel;
  final String stegoLabel;
  final double height;

  const DualWaveformChart({
    super.key,
    required this.coverEnvelope,
    required this.stegoEnvelope,
    required this.coverLabel,
    required this.stegoLabel,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final coverColor = scheme.primary;
    final stegoColor = scheme.tertiary;

    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: height,
            child: CustomPaint(
              painter: _DualWavePainter(
                cover: coverEnvelope,
                stego: stegoEnvelope,
                coverColor: coverColor,
                stegoColor: stegoColor,
                gridColor: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _LegendDot(color: coverColor, label: coverLabel),
              _LegendDot(color: stegoColor, label: stegoLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _DualWavePainter extends CustomPainter {
  final List<double> cover;
  final List<double> stego;
  final Color coverColor;
  final Color stegoColor;
  final Color gridColor;

  _DualWavePainter({
    required this.cover,
    required this.stego,
    required this.coverColor,
    required this.stegoColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), grid);

    if (cover.isNotEmpty) {
      _drawSeries(canvas, size, cover, coverColor, midY, dashed: false);
    }
    if (stego.isNotEmpty) {
      _drawSeries(canvas, size, stego, stegoColor, midY, dashed: true);
    }
  }

  void _drawSeries(
    Canvas canvas,
    Size size,
    List<double> samples,
    Color color,
    double midY, {
    required bool dashed,
  }) {
    final n = samples.length;
    if (n < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (dashed) {
      paint.strokeWidth = 1.75;
    }

    final topPath = Path();
    final bottomPath = Path();
    for (var i = 0; i < n; i++) {
      final x = i / (n - 1) * size.width;
      final amp = samples[i].clamp(0.0, 1.0) * (midY - 4);
      final yTop = midY - amp;
      final yBottom = midY + amp;
      if (i == 0) {
        topPath.moveTo(x, yTop);
        bottomPath.moveTo(x, yBottom);
      } else {
        topPath.lineTo(x, yTop);
        bottomPath.lineTo(x, yBottom);
      }
    }

    if (dashed) {
      _drawDashedPath(canvas, topPath, paint);
      _drawDashedPath(canvas, bottomPath, paint);
    } else {
      canvas.drawPath(topPath, paint);
      canvas.drawPath(bottomPath, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final len = (distance + dash).clamp(0.0, metric.length) - distance;
        final extract = metric.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DualWavePainter oldDelegate) =>
      oldDelegate.cover != cover ||
      oldDelegate.stego != stego ||
      oldDelegate.coverColor != coverColor ||
      oldDelegate.stegoColor != stegoColor;
}
