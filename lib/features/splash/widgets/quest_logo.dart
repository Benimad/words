import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';

/// The WordQuest brand mark, drawn entirely in code.
///
/// The concept: a **compass rose formed from letter tiles** — "quest"
/// (navigation) plus "word" (tiles), which is the whole game in one shape. It
/// is drawn with a painter rather than shipped as an image so it scales
/// perfectly at any size and can be animated (the ring sweeps and the tiles
/// settle) without a sprite sheet.
class QuestLogo extends StatelessWidget {
  const QuestLogo({
    super.key,
    this.size = 132,
    this.progress = 1.0,
    this.showLetters = true,
  });

  final double size;

  /// 0-1 assembly progress, driven by the splash animation.
  final double progress;
  final bool showLetters;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _QuestLogoPainter(
            progress: progress.clamp(0.0, 1.0),
            showLetters: showLetters,
          ),
        ),
      );
}

class _QuestLogoPainter extends CustomPainter {
  _QuestLogoPainter({required this.progress, required this.showLetters});

  final double progress;
  final bool showLetters;

  /// The four tiles spell the brand initial outward from the centre.
  static const _letters = ['W', 'Q', 'S', 'T'];

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;

    // --- Outer glow -----------------------------------------------------
    canvas.drawCircle(
      centre,
      radius * 0.98,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppPalette.violet.withValues(alpha: 0.35 * progress),
            AppPalette.violet.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );

    // --- Sweeping ring --------------------------------------------------
    final ringRect = Rect.fromCircle(center: centre, radius: radius * 0.78);
    canvas.drawArc(
      ringRect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.075
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [
            AppPalette.violetLight,
            AppPalette.teal,
            AppPalette.amber,
            AppPalette.violetLight,
          ],
        ).createShader(ringRect),
    );

    // --- Compass points -------------------------------------------------
    // Four diamonds at the cardinal directions, scaling in with a stagger.
    for (var i = 0; i < 4; i++) {
      final angle = -math.pi / 2 + i * math.pi / 2;
      // Each point starts its animation slightly after the previous one.
      final t = ((progress - 0.25 - i * 0.10) / 0.55).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final eased = Curves.easeOutBack.transform(t);
      final distance = radius * 0.46;
      final position = centre +
          Offset(math.cos(angle), math.sin(angle)) * distance;

      final tileSize = radius * 0.30 * eased;

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(math.pi / 4);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: tileSize,
          height: tileSize,
        ),
        Radius.circular(tileSize * 0.22),
      );

      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _tileColors[i].withValues(alpha: 0.95),
              Color.lerp(_tileColors[i], Colors.black, 0.28)!,
            ],
          ).createShader(rect.outerRect),
      );
      canvas.restore();

      if (showLetters && t > 0.55) {
        _drawLetter(
          canvas,
          _letters[i],
          position,
          tileSize * 0.52,
          ((t - 0.55) / 0.45).clamp(0.0, 1.0),
        );
      }
    }

    // --- Centre gem -----------------------------------------------------
    final gemScale = Curves.easeOutBack.transform(
      (progress / 0.4).clamp(0.0, 1.0),
    );
    final gemRadius = radius * 0.20 * gemScale;
    if (gemRadius > 0) {
      canvas.drawCircle(
        centre,
        gemRadius,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppPalette.violetLight],
          ).createShader(
            Rect.fromCircle(center: centre, radius: gemRadius),
          ),
      );
    }
  }

  static const _tileColors = [
    AppPalette.violet,
    AppPalette.teal,
    AppPalette.amber,
    AppPalette.rose,
  ];

  void _drawLetter(
    Canvas canvas,
    String letter,
    Offset centre,
    double fontSize,
    double opacity,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: letter,
        style: AppTypography.gridLetter(
          fontSize,
          Colors.white.withValues(alpha: opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      centre - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_QuestLogoPainter old) =>
      old.progress != progress || old.showLetters != showLetters;
}
