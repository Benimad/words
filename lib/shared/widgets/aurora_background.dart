import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// The app's signature backdrop: slow-drifting coloured light behind a dark or
/// light base.
///
/// Implemented as a single [CustomPaint] with a handful of blurred radial
/// gradients rather than real blur filters — `MaskFilter.blur` on a large area
/// is expensive on mid-range Android, while radial gradients are effectively
/// free and read identically at this softness.
///
/// The animation is very slow (a full cycle takes ~24s) and is paused whenever
/// [animate] is false, so it never competes with gameplay for attention or
/// battery.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    required this.child,
    this.accents,
    this.animate = true,
    this.intensity = 1.0,
  });

  final Widget child;

  /// Overrides the default brand colours — the game screen passes its world's
  /// accent so each region feels distinct.
  final List<Color>? accents;

  final bool animate;

  /// 0-1 multiplier on blob opacity. Lowered behind dense content like the
  /// puzzle board so text contrast stays high.
  final double intensity;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(AuroraBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accents = widget.accents ??
        const [AppPalette.violet, AppPalette.teal, AppPalette.rose];

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: isDark ? AppGradients.nightSky : AppGradients.daySky,
          ),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _AuroraPainter(
                progress: _controller.value,
                accents: accents,
                isDark: isDark,
                intensity: widget.intensity,
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.progress,
    required this.accents,
    required this.isDark,
    required this.intensity,
  });

  final double progress;
  final List<Color> accents;
  final bool isDark;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    // Each blob orbits on its own ellipse at its own speed and phase, so the
    // composition never visibly repeats within a session.
    final blobs = <_Blob>[
      _Blob(
        centre: Offset(
          size.width * (0.2 + 0.18 * math.sin(progress * 2 * math.pi)),
          size.height * (0.18 + 0.10 * math.cos(progress * 2 * math.pi)),
        ),
        radius: size.shortestSide * 0.75,
        color: accents[0],
      ),
      _Blob(
        centre: Offset(
          size.width * (0.85 + 0.14 * math.cos(progress * 2 * math.pi + 1.6)),
          size.height * (0.32 + 0.14 * math.sin(progress * 2 * math.pi + 1.6)),
        ),
        radius: size.shortestSide * 0.62,
        color: accents.length > 1 ? accents[1] : accents[0],
      ),
      _Blob(
        centre: Offset(
          size.width * (0.5 + 0.22 * math.sin(progress * 2 * math.pi + 3.2)),
          size.height * (0.88 + 0.08 * math.cos(progress * 2 * math.pi + 3.2)),
        ),
        radius: size.shortestSide * 0.8,
        color: accents.length > 2 ? accents[2] : accents.last,
      ),
    ];

    // Light mode needs far less alpha: coloured light on white reads much
    // stronger than the same light on near-black.
    final baseAlpha = (isDark ? 0.30 : 0.16) * intensity;

    for (final blob in blobs) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            blob.color.withValues(alpha: baseAlpha),
            blob.color.withValues(alpha: baseAlpha * 0.45),
            blob.color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(
          Rect.fromCircle(center: blob.centre, radius: blob.radius),
        );
      canvas.drawCircle(blob.centre, blob.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.progress != progress ||
      old.intensity != intensity ||
      old.isDark != isDark;
}

class _Blob {
  const _Blob({
    required this.centre,
    required this.radius,
    required this.color,
  });
  final Offset centre;
  final double radius;
  final Color color;
}
