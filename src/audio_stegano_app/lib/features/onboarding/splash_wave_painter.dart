import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated audio waveform for splash backgrounds.
class SplashWavePainter extends CustomPainter {
  final double phase;
  final Color waveColor;
  final Color glowColor;
  final bool showBits;

  SplashWavePainter({
    required this.phase,
    required this.waveColor,
    required this.glowColor,
    this.showBits = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height * 0.52;
    final path = Path();
    const points = 120;
    for (var i = 0; i <= points; i++) {
      final t = i / points;
      final x = t * size.width;
      final w1 = math.sin(t * math.pi * 6 + phase) * 28;
      final w2 = math.sin(t * math.pi * 14 + phase * 1.4) * 12;
      final y = midY + w1 + w2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final glow = Paint()
      ..color = glowColor.withValues(alpha: 0.35)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glow);

    final stroke = Paint()
      ..color = waveColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);

    if (showBits) {
      final rnd = math.Random(7);
      final bitPaint = Paint()..color = waveColor.withValues(alpha: 0.55);
      for (var i = 0; i < 24; i++) {
        final bx = rnd.nextDouble() * size.width;
        final by = midY - 60 + rnd.nextDouble() * 120;
        final bit = rnd.nextBool();
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(bx, by), width: 6, height: 10),
          const Radius.circular(2),
        );
        canvas.drawRRect(
          rect,
          bitPaint
            ..color = bit
                ? waveColor.withValues(alpha: 0.75)
                : waveColor.withValues(alpha: 0.25),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SplashWavePainter old) =>
      old.phase != phase || old.showBits != showBits;
}
