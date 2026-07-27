import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/app_strings.dart';
import '../../core/audio/spectrum_analyzer.dart';

/// Spectrum + master level meter — rounded gradient bars, volume clearly visible.
class AudioEqualizerView extends StatelessWidget {
  final List<double> bands;
  final bool active;
  final double height;

  /// Elapsed recording time; shown beside level % while recording.
  final Duration? recordingElapsed;

  const AudioEqualizerView({
    super.key,
    required this.bands,
    this.active = false,
    this.height = 128,
    this.recordingElapsed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uiTextDirection = Directionality.of(context);
    final normalized = _normalizeBands(bands);
    final hasSignal = active && normalized.any((v) => v > 0.05);
    final displayBands = hasSignal
        ? normalized
        : List<double>.filled(kSpectrumBandCount, 0.04);
    final peak = displayBands.fold<double>(0, math.max);
    final levelPercent = (peak * 100).clamp(0, 100).round();

    return ExcludeSemantics(
      child: Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    scheme.surfaceContainerHighest.withValues(alpha: 0.95),
                    scheme.surface.withValues(alpha: 0.9),
                  ]
                : [scheme.surfaceContainerHigh, scheme.surface],
          ),
          border: Border.all(
            color: active
                ? scheme.primary.withValues(alpha: 0.55)
                : scheme.outlineVariant.withValues(alpha: 0.6),
            width: active ? 1.5 : 1,
          ),
          boxShadow: active && hasSignal
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Physical LTR: volume % left · label center · timer right (locale-independent).
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  if (active)
                    _MetricBadge(
                      icon: Icons.volume_up_rounded,
                      label: '$levelPercent%',
                      color: _levelBadgeColor(scheme, peak),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.graphic_eq_rounded,
                          size: 16,
                          color: active
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Directionality(
                            textDirection: uiTextDirection,
                            child: Text(
                              AppStrings.of(context).audioLevel,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (recordingElapsed != null)
                    _MetricBadge(
                      icon: Icons.timer_outlined,
                      label: _formatDuration(recordingElapsed!),
                      color: scheme.primary,
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: CustomPaint(
                painter: _ModernEqualizerPainter(
                  bands: displayBands,
                  peak: peak,
                  active: active,
                  hasSignal: hasSignal,
                  primary: scheme.primary,
                  tertiary: scheme.tertiary,
                  error: scheme.error,
                  track: scheme.outlineVariant.withValues(alpha: 0.35),
                  idle: scheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) {
      return '$h:$m:$s';
    }
    return '$m:$s';
  }

  static Color _levelBadgeColor(ColorScheme scheme, double peak) {
    if (peak < 0.45) return scheme.primary;
    if (peak < 0.78) return scheme.tertiary;
    return scheme.error;
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

class _MetricBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetricBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernEqualizerPainter extends CustomPainter {
  final List<double> bands;
  final double peak;
  final bool active;
  final bool hasSignal;
  final Color primary;
  final Color tertiary;
  final Color error;
  final Color track;
  final Color idle;

  _ModernEqualizerPainter({
    required this.bands,
    required this.peak,
    required this.active,
    required this.hasSignal,
    required this.primary,
    required this.tertiary,
    required this.error,
    required this.track,
    required this.idle,
  });

  static const _meterWidth = 14.0;
  static const _meterGap = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);

    final meterRect = Rect.fromLTWH(0, 0, _meterWidth, size.height);
    _drawMasterMeter(canvas, meterRect);

    final barsLeft = _meterWidth + _meterGap;
    final barsW = size.width - barsLeft;
    final barsRect = Rect.fromLTWH(barsLeft, 0, barsW, size.height);
    _drawSpectrumBars(canvas, barsRect);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = track
      ..strokeWidth = 1;
    for (final f in [0.25, 0.5, 0.75]) {
      final y = size.height * (1 - f);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawMasterMeter(Canvas canvas, Rect rect) {
    final trackR = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(trackR, Paint()..color = track.withValues(alpha: 0.5));

    final fillH = rect.height * peak.clamp(0.04, 1.0);
    final fillRect = Rect.fromLTWH(
      rect.left,
      rect.bottom - fillH,
      rect.width,
      fillH,
    );
    final fillR = RRect.fromRectAndRadius(fillRect, const Radius.circular(6));
    final shader = ui.Gradient.linear(fillRect.bottomLeft, fillRect.topLeft, [
      _colorForLevel(0),
      _colorForLevel(peak),
    ]);
    canvas.drawRRect(fillR, Paint()..shader = shader);

    if (hasSignal && peak > 0.12) {
      final peakY = rect.bottom - rect.height * peak;
      canvas.drawLine(
        Offset(rect.left - 2, peakY),
        Offset(rect.right + 2, peakY),
        Paint()
          ..color = _colorForLevel(peak)
          ..strokeWidth = 2,
      );
    }
  }

  void _drawSpectrumBars(Canvas canvas, Rect rect) {
    const gap = 3.0;
    final count = bands.length;
    final barW = (rect.width - gap * (count - 1)) / count;
    final minH = rect.height * 0.06;

    for (var i = 0; i < count; i++) {
      final norm = bands[i].clamp(0.0, 1.0);
      final h = math.max(minH, norm * rect.height);
      final x = rect.left + i * (barW + gap);
      final barRect = Rect.fromLTWH(x, rect.bottom - h, barW, h);
      final radius = Radius.circular(math.min(barW / 2, 5));
      final rrect = RRect.fromRectAndCorners(
        barRect,
        topLeft: radius,
        topRight: radius,
        bottomLeft: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, rect.top, barW, rect.height),
          const Radius.circular(4),
        ),
        Paint()..color = track.withValues(alpha: 0.35),
      );

      if (!active || !hasSignal) {
        canvas.drawRRect(rrect, Paint()..color = idle);
        continue;
      }

      final shader = ui.Gradient.linear(barRect.bottomLeft, barRect.topLeft, [
        primary.withValues(alpha: 0.85),
        _colorForLevel(norm),
      ]);
      canvas.drawRRect(rrect, Paint()..shader = shader);

      if (norm > 0.2) {
        canvas.drawRRect(
          rrect.inflate(0.5),
          Paint()
            ..color = _colorForLevel(norm).withValues(alpha: 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
  }

  Color _colorForLevel(double t) {
    if (t < 0.5) return Color.lerp(primary, tertiary, t / 0.5)!;
    if (t < 0.82) {
      return Color.lerp(
        tertiary,
        error.withValues(alpha: 0.65),
        (t - 0.5) / 0.32,
      )!;
    }
    return Color.lerp(error.withValues(alpha: 0.65), error, (t - 0.82) / 0.18)!;
  }

  @override
  bool shouldRepaint(covariant _ModernEqualizerPainter old) =>
      !listEquals(old.bands, bands) ||
      old.peak != peak ||
      old.active != active ||
      old.hasSignal != hasSignal;
}
