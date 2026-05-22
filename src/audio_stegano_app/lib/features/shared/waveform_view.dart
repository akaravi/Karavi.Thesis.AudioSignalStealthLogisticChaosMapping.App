import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Rolling bars representing live amplitude (dBFS in [-160..0]).
class WaveformView extends StatelessWidget {
  final List<double> samples;
  final bool active;
  final double height;

  const WaveformView({
    super.key,
    required this.samples,
    this.active = false,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _WavePainter(
            samples: samples,
            color: active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final List<double> samples;
  final Color color;
  _WavePainter({required this.samples, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) {
      _drawIdle(canvas, size);
      return;
    }
    const barWidth = 4.0;
    const gap = 3.0;
    final maxBars = (size.width / (barWidth + gap)).floor();
    final visible = samples.length > maxBars
        ? samples.sublist(samples.length - maxBars)
        : samples;
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    for (var i = 0; i < visible.length; i++) {
      final db = visible[i].clamp(-60.0, 0.0);
      final norm = (db + 60.0) / 60.0;
      final h = math.max(2.0, norm * size.height);
      final x = i * (barWidth + gap) + barWidth / 2;
      final y1 = (size.height - h) / 2;
      final y2 = y1 + h;
      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  void _drawIdle(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.samples != samples || oldDelegate.color != color;
}
