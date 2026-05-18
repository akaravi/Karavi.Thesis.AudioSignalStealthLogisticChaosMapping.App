import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/audio/spectrum_analyzer.dart';

/// Classic vertical-bar audio equalizer (spectrum) display.
class AudioEqualizerView extends StatelessWidget {
  final List<double> bands;
  final bool active;
  final double height;

  const AudioEqualizerView({
    super.key,
    required this.bands,
    this.active = false,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = _normalizeBands(bands);
    final hasSignal = normalized.any((v) => v > 0.06);
    final barColor = active && hasSignal
        ? scheme.primary
        : active
        ? scheme.primary.withValues(alpha: 0.55)
        : scheme.outline;
    final glow = active
        ? scheme.primary.withValues(alpha: hasSignal ? 0.4 : 0.2)
        : null;
    final displayBands = active || hasSignal
        ? normalized
        : _idlePlaceholderBars();

    return ExcludeSemantics(
      child: Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.85),
          border: Border.all(
            color: active
                ? scheme.primary.withValues(alpha: 0.45)
                : scheme.outlineVariant,
            width: active ? 1.5 : 1,
          ),
        ),
        child: CustomPaint(
          painter: _EqualizerPainter(
            bands: displayBands,
            barColor: barColor,
            glowColor: glow,
            minBarFraction: active ? 0.04 : 0.14,
          ),
        ),
      ),
    );
  }

  static List<double> _idlePlaceholderBars() {
    const pattern = [
      0.18,
      0.28,
      0.42,
      0.55,
      0.62,
      0.7,
      0.75,
      0.8,
      0.82,
      0.85,
      0.88,
      0.9,
      0.88,
      0.85,
      0.82,
      0.8,
      0.75,
      0.7,
      0.62,
      0.55,
      0.42,
      0.28,
      0.18,
      0.12,
      0.18,
      0.28,
      0.42,
      0.55,
      0.62,
      0.7,
      0.75,
      0.8,
    ];
    return List<double>.from(pattern);
  }

  static List<double> _normalizeBands(List<double> bands) {
    if (bands.length == kSpectrumBandCount) return bands;
    if (bands.isEmpty) return List<double>.filled(kSpectrumBandCount, 0);
    final out = List<double>.filled(kSpectrumBandCount, 0);
    for (var i = 0; i < kSpectrumBandCount; i++) {
      final src = (i * bands.length / kSpectrumBandCount).floor();
      out[i] = bands[src.clamp(0, bands.length - 1)];
    }
    return out;
  }
}

class _EqualizerPainter extends CustomPainter {
  final List<double> bands;
  final Color barColor;
  final Color? glowColor;
  final double minBarFraction;

  _EqualizerPainter({
    required this.bands,
    required this.barColor,
    this.glowColor,
    this.minBarFraction = 0.04,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 2.0;
    final count = bands.length;
    final barWidth = (size.width - gap * (count - 1)) / count;
    final paint = Paint()..color = barColor;
    final minH = size.height * minBarFraction;

    for (var i = 0; i < count; i++) {
      final norm = bands[i].clamp(0.0, 1.0);
      final h = math.max(minH, norm * size.height);
      final x = i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, barWidth, h),
        const Radius.circular(2),
      );
      if (glowColor != null && norm > 0.08) {
        canvas.drawRRect(rect.inflate(1), Paint()..color = glowColor!);
      }
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EqualizerPainter oldDelegate) =>
      !listEquals(oldDelegate.bands, bands) ||
      oldDelegate.barColor != barColor ||
      oldDelegate.glowColor != glowColor ||
      oldDelegate.minBarFraction != minBarFraction;
}
