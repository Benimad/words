import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// A hand-rolled confetti burst.
///
/// Written from scratch rather than pulled from a package for two reasons: it
/// keeps the dependency list honest, and it lets the particles match the app's
/// exact palette and physics (a short upward impulse, gravity, air drag and
/// per-particle spin) instead of generic falling rectangles.
///
/// Everything is drawn in **one** [CustomPaint] pass inside a
/// [RepaintBoundary], so 90 particles cost a single layer.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.play,
    this.particleCount = 90,
    this.colors,
    this.duration = const Duration(milliseconds: 2600),
  });

  /// Flip to true to fire a burst. Setting it true again after a reset
  /// re-fires.
  final bool play;
  final int particleCount;
  final List<Color>? colors;
  final Duration duration;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  List<_Particle> _particles = const [];

  @override
  void initState() {
    super.initState();
    if (widget.play) _fire();
  }

  @override
  void didUpdateWidget(CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) _fire();
  }

  void _fire() {
    final rng = math.Random();
    final palette = widget.colors ??
        const [
          AppPalette.violet,
          AppPalette.teal,
          AppPalette.amber,
          AppPalette.mint,
          AppPalette.rose,
          AppPalette.sky,
        ];

    _particles = List.generate(widget.particleCount, (i) {
      // Two launch points (left and right of centre) reads more like a real
      // confetti cannon than a single origin.
      final fromLeft = i.isEven;
      return _Particle(
        origin: Offset(fromLeft ? 0.18 : 0.82, 0.62),
        // Aim inward and upward, with spread.
        velocity: Offset(
          (fromLeft ? 1 : -1) * (0.22 + rng.nextDouble() * 0.5),
          -(0.85 + rng.nextDouble() * 0.7),
        ),
        color: palette[rng.nextInt(palette.length)],
        size: 5 + rng.nextDouble() * 7,
        spin: (rng.nextDouble() - 0.5) * 14,
        shape: _Shape.values[rng.nextInt(_Shape.values.length)],
        delay: rng.nextDouble() * 0.18,
      );
    });

    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          ),
        ),
      ),
    );
  }
}

enum _Shape { rect, circle, strip }

class _Particle {
  const _Particle({
    required this.origin,
    required this.velocity,
    required this.color,
    required this.size,
    required this.spin,
    required this.shape,
    required this.delay,
  });

  /// Normalised (0-1) launch point.
  final Offset origin;

  /// Normalised velocity in screen-heights per second.
  final Offset velocity;
  final Color color;
  final double size;
  final double spin;
  final _Shape shape;

  /// Fraction of the total animation to wait before launching.
  final double delay;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  /// Downward acceleration, in screen-heights per second squared.
  static const _gravity = 1.9;

  /// Horizontal velocity decay per second — stops particles flying off-screen.
  static const _drag = 0.55;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final t = (progress - p.delay) / (1 - p.delay);
      if (t <= 0) continue;

      // Simple ballistic integration, good enough and cheap.
      final dx = p.velocity.dx * t * (1 - _drag * t * 0.5);
      final dy = p.velocity.dy * t + 0.5 * _gravity * t * t;

      final x = (p.origin.dx + dx) * size.width;
      final y = (p.origin.dy + dy) * size.height;

      // Skip anything that has left the frame.
      if (y > size.height + 40 || x < -40 || x > size.width + 40) continue;

      // Fade out over the last third so particles dissolve rather than vanish.
      final alpha = t < 0.66 ? 1.0 : (1 - (t - 0.66) / 0.34).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);

      switch (p.shape) {
        case _Shape.rect:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.size,
                height: p.size * 0.62,
              ),
              const Radius.circular(1.5),
            ),
            paint,
          );
        case _Shape.circle:
          canvas.drawCircle(Offset.zero, p.size * 0.42, paint);
        case _Shape.strip:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.size * 0.34,
                height: p.size * 1.5,
              ),
              const Radius.circular(1),
            ),
            paint,
          );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.progress != progress || old.particles != particles;
}

/// A single expanding ring — used under a medal or a "level up" badge to give
/// the moment a focal point.
class PulseRing extends StatefulWidget {
  const PulseRing({
    super.key,
    required this.child,
    required this.color,
    this.rings = 3,
    this.period = const Duration(milliseconds: 2200),
    this.maxScale = 2.4,
  });

  final Widget child;
  final Color color;
  final int rings;
  final Duration period;
  final double maxScale;

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < widget.rings; i++)
              _ring((_controller.value + i / widget.rings) % 1.0),
            child!,
          ],
        ),
        child: widget.child,
      );

  Widget _ring(double t) {
    final scale = 1 + (widget.maxScale - 1) * t;
    return Opacity(
      opacity: (1 - t) * 0.45,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.color, width: 2),
          ),
        ),
      ),
    );
  }
}
