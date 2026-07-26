import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';

/// Animated vector illustrations for the onboarding pages.
///
/// These are built from primitives rather than shipped as images: they animate
/// (a finger actually swipes across a mini-grid, a map path actually draws
/// itself), they cost nothing in APK size, and they recolour automatically with
/// the theme.

/// Page 1 — a small grid where a word is swiped and highlighted on a loop.
class SwipeDemoIllustration extends StatefulWidget {
  const SwipeDemoIllustration({super.key, this.size = 220});
  final double size;

  @override
  State<SwipeDemoIllustration> createState() => _SwipeDemoIllustrationState();
}

class _SwipeDemoIllustrationState extends State<SwipeDemoIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  // A 4x4 mini board with "WORD" running along the diagonal.
  static const _grid = [
    ['W', 'K', 'T', 'A'],
    ['L', 'O', 'E', 'S'],
    ['P', 'M', 'R', 'N'],
    ['C', 'I', 'B', 'D'],
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // The loop: swipe (0-45%), hold the found state (45-80%), reset.
          final raw = _controller.value;
          final swipe = (raw / 0.45).clamp(0.0, 1.0);
          final eased = Curves.easeInOutCubic.transform(swipe);
          final holding = raw > 0.45 && raw < 0.85;

          return CustomPaint(
            painter: _SwipeDemoPainter(
              grid: _grid,
              progress: eased,
              found: holding,
              surface: theme.colorScheme.surfaceContainerHigh,
              border: theme.colorScheme.outline,
              text: theme.colorScheme.onSurface,
            ),
          );
        },
      ),
    );
  }
}

class _SwipeDemoPainter extends CustomPainter {
  _SwipeDemoPainter({
    required this.grid,
    required this.progress,
    required this.found,
    required this.surface,
    required this.border,
    required this.text,
  });

  final List<List<String>> grid;
  final double progress;
  final bool found;
  final Color surface;
  final Color border;
  final Color text;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 4;
    final gap = size.width * 0.035;
    final cell = (size.width - gap * (n - 1)) / n;

    Offset centreOf(int r, int c) => Offset(
          c * (cell + gap) + cell / 2,
          r * (cell + gap) + cell / 2,
        );

    // Tiles.
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(c * (cell + gap), r * (cell + gap), cell, cell),
          Radius.circular(cell * 0.26),
        );
        canvas
          ..drawRRect(rect, Paint()..color = surface)
          ..drawRRect(
            rect,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2
              ..color = border,
          );

        _letter(canvas, grid[r][c], centreOf(r, c), cell * 0.42, text);
      }
    }

    // The swipe ribbon along the diagonal (0,0) -> (3,3).
    final start = centreOf(0, 0);
    final end = centreOf(3, 3);
    final current = Offset.lerp(start, end, progress)!;

    final ribbonColor = found ? AppPalette.mint : AppPalette.violet;
    canvas.drawLine(
      start,
      current,
      Paint()
        ..color = ribbonColor.withValues(alpha: 0.55)
        ..strokeWidth = cell * 0.78
        ..strokeCap = StrokeCap.round,
    );

    // Redraw the covered letters on top so they stay legible.
    for (var i = 0; i < n; i++) {
      final p = centreOf(i, i);
      final reached = progress >= i / (n - 1) - 0.01;
      if (reached) {
        _letter(canvas, grid[i][i], p, cell * 0.42, Colors.white);
      }
    }

    // Fingertip.
    if (!found) {
      canvas
        ..drawCircle(
          current,
          cell * 0.30,
          Paint()..color = Colors.white.withValues(alpha: 0.30),
        )
        ..drawCircle(
          current,
          cell * 0.17,
          Paint()..color = Colors.white.withValues(alpha: 0.92),
        );
    }
  }

  void _letter(
    Canvas canvas,
    String glyph,
    Offset centre,
    double fontSize,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: AppTypography.gridLetter(fontSize, color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      centre - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_SwipeDemoPainter old) =>
      old.progress != progress || old.found != found || old.text != text;
}

/// Page 2 — a winding map path whose nodes light up one by one.
class JourneyIllustration extends StatefulWidget {
  const JourneyIllustration({super.key, this.size = 220});
  final double size;

  @override
  State<JourneyIllustration> createState() => _JourneyIllustrationState();
}

class _JourneyIllustrationState extends State<JourneyIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _JourneyPainter(
            progress: _controller.value,
            track: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}

class _JourneyPainter extends CustomPainter {
  _JourneyPainter({required this.progress, required this.track});

  final double progress;
  final Color track;

  static const _accents = [
    AppPalette.mint,
    AppPalette.sky,
    AppPalette.orange,
    AppPalette.rose,
    AppPalette.violetLight,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Five nodes on a serpentine path.
    final nodes = [
      Offset(size.width * 0.18, size.height * 0.86),
      Offset(size.width * 0.42, size.height * 0.68),
      Offset(size.width * 0.26, size.height * 0.46),
      Offset(size.width * 0.60, size.height * 0.32),
      Offset(size.width * 0.82, size.height * 0.14),
    ];

    // Dashed base track.
    final path = Path()..moveTo(nodes.first.dx, nodes.first.dy);
    for (var i = 1; i < nodes.length; i++) {
      final prev = nodes[i - 1];
      final next = nodes[i];
      // Quadratic control point offset perpendicular-ish for a natural curve.
      final control = Offset(
        (prev.dx + next.dx) / 2 + (i.isEven ? 22 : -22),
        (prev.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(control.dx, control.dy, next.dx, next.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = track,
    );

    // Progress overlay — the travelled portion of the path.
    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final travelled = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(
        travelled,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(
            colors: [AppPalette.mint, AppPalette.violetLight],
          ).createShader(Offset.zero & size),
      );
    }

    // Nodes light up as the path reaches them.
    for (var i = 0; i < nodes.length; i++) {
      final threshold = i / (nodes.length - 1);
      final lit = progress >= threshold * 0.95;
      final pop = lit
          ? Curves.easeOutBack.transform(
              ((progress - threshold * 0.95) / 0.12).clamp(0.0, 1.0),
            )
          : 0.0;

      final radius = 9.0 + 7 * pop;
      canvas
        ..drawCircle(
          nodes[i],
          radius + 5,
          Paint()
            ..color = _accents[i].withValues(alpha: 0.22 * pop),
        )
        ..drawCircle(
          nodes[i],
          radius,
          Paint()..color = lit ? _accents[i] : track,
        );

      if (lit && pop > 0.6) {
        final painter = TextPainter(
          text: TextSpan(
            text: '★',
            style: TextStyle(
              fontSize: radius * 0.9,
              color: Colors.white.withValues(alpha: pop),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(
          canvas,
          nodes[i] - Offset(painter.width / 2, painter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_JourneyPainter old) => old.progress != progress;
}

/// Page 3 — coins arcing into a growing pile.
class RewardsIllustration extends StatefulWidget {
  const RewardsIllustration({super.key, this.size = 220});
  final double size;

  @override
  State<RewardsIllustration> createState() => _RewardsIllustrationState();
}

class _RewardsIllustrationState extends State<RewardsIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _RewardsPainter(progress: _controller.value),
          ),
        ),
      );
}

class _RewardsPainter extends CustomPainter {
  _RewardsPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final chestTop = size.height * 0.68;

    // Six coins, each on its own phase of the loop.
    for (var i = 0; i < 6; i++) {
      final phase = (progress + i / 6) % 1.0;
      final t = Curves.easeInQuad.transform(phase);

      final startX = size.width * (0.18 + 0.13 * i);
      final x = startX + (size.width * 0.5 - startX) * t;
      // Parabolic arc: up then down into the chest.
      final y = size.height * 0.18 + (chestTop - size.height * 0.18) * t * t;

      final radius = size.width * 0.055;
      final alpha = phase > 0.9 ? (1 - (phase - 0.9) / 0.1) : 1.0;

      canvas
        ..drawCircle(
          Offset(x, y),
          radius,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppPalette.amberLight, AppPalette.amberDark],
            ).createShader(
              Rect.fromCircle(center: Offset(x, y), radius: radius),
            )
            ..color = Colors.white.withValues(alpha: alpha),
        )
        ..drawCircle(
          Offset(x, y),
          radius * 0.55,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = Colors.white.withValues(alpha: 0.55 * alpha),
        );
    }

    // Chest.
    final chestRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.26,
        chestTop,
        size.width * 0.48,
        size.height * 0.22,
      ),
      Radius.circular(size.width * 0.05),
    );
    canvas.drawRRect(
      chestRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.violetLight, AppPalette.violetDark],
        ).createShader(chestRect.outerRect),
    );

    // Lock plate.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, chestTop + size.height * 0.10),
          width: size.width * 0.11,
          height: size.height * 0.09,
        ),
        Radius.circular(size.width * 0.02),
      ),
      Paint()..color = AppPalette.amber,
    );

    // Glow above the chest that pulses with the loop.
    final glow = 0.25 + 0.2 * math.sin(progress * 2 * math.pi);
    canvas.drawCircle(
      Offset(size.width * 0.5, chestTop),
      size.width * 0.30,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppPalette.amber.withValues(alpha: glow),
            AppPalette.amber.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.5, chestTop),
            radius: size.width * 0.30,
          ),
        ),
    );
  }

  @override
  bool shouldRepaint(_RewardsPainter old) => old.progress != progress;
}

/// Page 4 — a flame with a streak counter, for the daily challenge.
class StreakIllustration extends StatefulWidget {
  const StreakIllustration({super.key, this.size = 220});
  final double size;

  @override
  State<StreakIllustration> createState() => _StreakIllustrationState();
}

class _StreakIllustrationState extends State<StreakIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_controller.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              // Seven day pips in a ring — the week of a streak.
              for (var i = 0; i < 7; i++)
                Transform.translate(
                  offset: Offset.fromDirection(
                    -math.pi / 2 + i * (2 * math.pi / 7),
                    widget.size * 0.36,
                  ),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= 4
                          ? AppPalette.amber
                          : theme.colorScheme.outline,
                      boxShadow: i <= 4
                          ? [
                              BoxShadow(
                                color: AppPalette.amber
                                    .withValues(alpha: 0.4 * t),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: i <= 4
                        ? const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              Transform.scale(
                scale: 1 + 0.08 * t,
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: widget.size * 0.42,
                  color: Color.lerp(
                    AppPalette.orange,
                    AppPalette.amberLight,
                    t,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
