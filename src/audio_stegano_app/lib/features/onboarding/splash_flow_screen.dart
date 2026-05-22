import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_strings.dart';
import '../../app/app_version.dart';
import 'splash_wave_painter.dart';

/// Two themed splash screens: audio wave, then steganography / chaos.
class SplashFlowScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashFlowScreen({super.key, required this.onComplete});

  @override
  State<SplashFlowScreen> createState() => _SplashFlowScreenState();
}

class _SplashFlowScreenState extends State<SplashFlowScreen>
    with TickerProviderStateMixin {
  static const _splashDuration = Duration(milliseconds: 2800);

  late final AnimationController _waveCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fadeCtrl.forward();
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(_splashDuration, () async {
      if (!mounted) return;
      await _fadeCtrl.reverse();
      if (!mounted) return;
      if (_page == 0) {
        setState(() => _page = 1);
        await _fadeCtrl.forward();
        if (!mounted) return;
        _scheduleNext();
      } else {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveCtrl.dispose();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut),
        child: _page == 0
            ? _SplashPage(
                wavePhase: _waveCtrl,
                pulse: _pulseCtrl,
                icon: Icons.graphic_eq_rounded,
                title: s.splashTitleAudio,
                subtitle: s.splashSubtitleAudio,
                showBits: false,
                showVersion: true,
                versionLabel: '${s.aboutVersion}: ${AppVersion.display}',
              )
            : _SplashPage(
                wavePhase: _waveCtrl,
                pulse: _pulseCtrl,
                icon: Icons.shield_outlined,
                title: s.splashTitleStego,
                subtitle: s.splashSubtitleStego,
                showBits: true,
              ),
      ),
    );
  }
}

class _SplashPage extends StatelessWidget {
  final Animation<double> wavePhase;
  final Animation<double> pulse;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showBits;
  final bool showVersion;
  final String? versionLabel;

  const _SplashPage({
    required this.wavePhase,
    required this.pulse,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.showBits,
    this.showVersion = false,
    this.versionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgTop = Color.lerp(
      scheme.primary,
      scheme.surface,
      isDark ? 0.15 : 0.05,
    )!;
    final bgBottom = scheme.surface;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgTop,
            bgBottom,
            scheme.primaryContainer.withValues(alpha: 0.35),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: wavePhase,
            builder: (context, _) {
              return CustomPaint(
                painter: SplashWavePainter(
                  phase: wavePhase.value * math.pi * 2,
                  waveColor: scheme.primary,
                  glowColor: scheme.secondary,
                  showBits: showBits,
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  AnimatedBuilder(
                    animation: pulse,
                    builder: (context, child) {
                      final scale = 1 + pulse.value * 0.08;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [scheme.primary, scheme.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.45),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 56, color: scheme.onPrimary),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  if (showVersion && versionLabel != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      versionLabel!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
