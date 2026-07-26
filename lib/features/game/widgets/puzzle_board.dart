import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/grid_position.dart';
import '../../../state/game_session_controller.dart';

/// The interactive letter grid.
///
/// ## Why one `CustomPaint` instead of a widget per cell
///
/// A 13x13 board is 169 cells. As a widget tree that is 169 `Container`s to
/// lay out, plus repaints on every pointer move during a swipe. Painting the
/// whole board in a single pass keeps a drag at a steady 60fps even on low-end
/// hardware, and lets the found-word "ribbons" be drawn *under* the letters,
/// which is impossible with stacked per-cell widgets.
///
/// ## Hit testing
///
/// The gesture layer converts a local offset straight to a [GridPosition] with
/// integer division. A generous ~86% inner hit radius per cell means a finger
/// resting on a gap between two tiles does not flicker between them.
class PuzzleBoard extends StatefulWidget {
  const PuzzleBoard({
    super.key,
    required this.controller,
    required this.accent,
    required this.highContrast,
    required this.largeLetters,
    required this.onCellEntered,
    required this.onSelectionEnd,
  });

  final GameSessionController controller;
  final Color accent;
  final bool highContrast;
  final bool largeLetters;

  /// Fired once per newly-entered cell during a drag (sound + haptic).
  final VoidCallback onCellEntered;

  /// Fired when the finger lifts.
  final VoidCallback onSelectionEnd;

  @override
  State<PuzzleBoard> createState() => _PuzzleBoardState();
}

class _PuzzleBoardState extends State<PuzzleBoard>
    with TickerProviderStateMixin {
  /// Animates the most recently found word's ribbon drawing itself in.
  late final AnimationController _revealController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  /// Subtle idle shimmer over hinted cells so they stay noticeable.
  late final AnimationController _hintController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  int _lastFoundCount = 0;

  /// Cached text layouts, keyed by "letter|size|colorValue". Re-laying out 169
  /// `TextPainter`s per frame during a drag is the single biggest cost on this
  /// screen; caching makes it negligible.
  final Map<String, TextPainter> _textCache = {};

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final count = widget.controller.foundWords.length;
    if (count > _lastFoundCount) {
      _revealController.forward(from: 0);
    }
    _lastFoundCount = count;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _revealController.dispose();
    _hintController.dispose();
    for (final painter in _textCache.values) {
      painter.dispose();
    }
    super.dispose();
  }

  // --- Geometry ---------------------------------------------------------

  double _cellSize(Size size) {
    final controller = widget.controller;
    // Grids are square in this game, but the maths handles rectangles too.
    final byWidth = size.width / controller.puzzle.cols;
    final byHeight = size.height / controller.puzzle.rows;
    return byWidth < byHeight ? byWidth : byHeight;
  }

  GridPosition? _positionAt(Offset local, Size size) {
    final cell = _cellSize(size);
    if (cell <= 0) return null;

    final controller = widget.controller;
    // Centre the board inside whatever box we were given.
    final boardWidth = cell * controller.puzzle.cols;
    final boardHeight = cell * controller.puzzle.rows;
    final originX = (size.width - boardWidth) / 2;
    final originY = (size.height - boardHeight) / 2;

    final x = local.dx - originX;
    final y = local.dy - originY;
    if (x < 0 || y < 0 || x >= boardWidth || y >= boardHeight) return null;

    final col = (x / cell).floor();
    final row = (y / cell).floor();

    // Ignore touches in the outer 14% of a cell (the visual gap): this stops
    // the selection jittering between neighbours mid-swipe.
    final fx = (x / cell) - col;
    final fy = (y / cell) - row;
    const margin = 0.07;
    if (fx < margin || fx > 1 - margin || fy < margin || fy > 1 - margin) {
      // Still accept it if this is already the selected cell — otherwise the
      // line would drop out while the finger sits on a boundary.
      final candidate = GridPosition(row, col);
      final selection = widget.controller.selection;
      if (selection.isNotEmpty && selection.last == candidate) return candidate;
    }

    return GridPosition(row, col);
  }

  // --- Gestures ---------------------------------------------------------

  void _handleStart(Offset local, Size size) {
    final position = _positionAt(local, size);
    if (position == null) return;
    widget.controller.beginSelection(position);
    widget.onCellEntered();
  }

  void _handleUpdate(Offset local, Size size) {
    final position = _positionAt(local, size);
    if (position == null) return;
    if (widget.controller.extendSelection(position)) {
      widget.onCellEntered();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _handleStart(details.localPosition, size),
          onPanUpdate: (details) => _handleUpdate(details.localPosition, size),
          onPanEnd: (_) => widget.onSelectionEnd(),
          onPanCancel: () => controller.clearSelection(),
          // A tap is treated as a one-cell selection so the tick still fires;
          // `endSelection` discards it as too short.
          onTapDown: (details) => _handleStart(details.localPosition, size),
          onTapUp: (_) => controller.clearSelection(),
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                controller,
                _revealController,
                _hintController,
              ]),
              builder: (context, _) => CustomPaint(
                size: size,
                painter: _BoardPainter(
                  controller: controller,
                  accent: widget.accent,
                  revealProgress: _revealController.value,
                  hintPulse: _hintController.value,
                  highContrast: widget.highContrast,
                  largeLetters: widget.largeLetters,
                  isDark: theme.brightness == Brightness.dark,
                  tileColor: theme.colorScheme.surfaceContainerHigh,
                  tileBorder: theme.colorScheme.outline,
                  letterColor: theme.colorScheme.onSurface,
                  mutedLetterColor: theme.colorScheme.onSurfaceVariant,
                  textCache: _textCache,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.controller,
    required this.accent,
    required this.revealProgress,
    required this.hintPulse,
    required this.highContrast,
    required this.largeLetters,
    required this.isDark,
    required this.tileColor,
    required this.tileBorder,
    required this.letterColor,
    required this.mutedLetterColor,
    required this.textCache,
  });

  final GameSessionController controller;
  final Color accent;
  final double revealProgress;
  final double hintPulse;
  final bool highContrast;
  final bool largeLetters;
  final bool isDark;
  final Color tileColor;
  final Color tileBorder;
  final Color letterColor;
  final Color mutedLetterColor;
  final Map<String, TextPainter> textCache;

  /// Each found word gets its own colour, cycling through this palette so
  /// adjacent solutions never blur together.
  static const _ribbonPalette = [
    AppPalette.mint,
    AppPalette.sky,
    AppPalette.rose,
    AppPalette.orange,
    AppPalette.violetLight,
    AppPalette.teal,
    AppPalette.lime,
    AppPalette.amber,
    Color(0xFF60A5FA),
    Color(0xFFF87171),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (!controller.isReady) return;

    final puzzle = controller.puzzle;
    final cell = _cell(size);
    final boardWidth = cell * puzzle.cols;
    final boardHeight = cell * puzzle.rows;
    final origin = Offset(
      (size.width - boardWidth) / 2,
      (size.height - boardHeight) / 2,
    );

    Offset centreOf(GridPosition p) => origin +
        Offset(p.col * cell + cell / 2, p.row * cell + cell / 2);

    _paintTiles(canvas, puzzle.rows, puzzle.cols, cell, origin);
    _paintFoundRibbons(canvas, cell, centreOf);
    _paintSelectionRibbon(canvas, cell, centreOf);
    _paintLetters(canvas, cell, origin, centreOf);
  }

  double _cell(Size size) {
    final puzzle = controller.puzzle;
    final byWidth = size.width / puzzle.cols;
    final byHeight = size.height / puzzle.rows;
    return byWidth < byHeight ? byWidth : byHeight;
  }

  // --- Layers -----------------------------------------------------------

  void _paintTiles(
    Canvas canvas,
    int rows,
    int cols,
    double cell,
    Offset origin,
  ) {
    // Inset each tile so a visible gutter separates neighbours — essential for
    // reading a diagonal at a glance.
    final inset = cell * 0.06;
    final radius = Radius.circular(cell * 0.22);

    final fill = Paint()..color = tileColor.withValues(alpha: isDark ? 0.55 : 0.9);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = tileBorder.withValues(alpha: 0.7);

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            origin.dx + c * cell + inset,
            origin.dy + r * cell + inset,
            cell - inset * 2,
            cell - inset * 2,
          ),
          radius,
        );
        canvas
          ..drawRRect(rect, fill)
          ..drawRRect(rect, stroke);
      }
    }
  }

  /// Rounded capsules under solved words.
  void _paintFoundRibbons(
    Canvas canvas,
    double cell,
    Offset Function(GridPosition) centreOf,
  ) {
    final found = controller.foundWords;

    for (var i = 0; i < found.length; i++) {
      final word = found[i];
      final color = _ribbonPalette[word.orderFound % _ribbonPalette.length];

      // Only the newest ribbon animates; the rest are already at full length.
      final isNewest = i == found.length - 1;
      final t = isNewest
          ? Curves.easeOutCubic.transform(revealProgress.clamp(0.0, 1.0))
          : 1.0;
      if (t <= 0) continue;

      final start = centreOf(word.placed.cells.first);
      final fullEnd = centreOf(word.placed.cells.last);
      final end = Offset.lerp(start, fullEnd, t)!;

      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = color.withValues(alpha: highContrast ? 0.95 : 0.78)
          ..strokeWidth = cell * 0.80
          ..strokeCap = StrokeCap.round,
      );

      // A brighter core line gives the ribbon dimension.
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = Color.lerp(color, Colors.white, 0.28)!
              .withValues(alpha: 0.35)
          ..strokeWidth = cell * 0.52
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// The live ribbon under the finger.
  void _paintSelectionRibbon(
    Canvas canvas,
    double cell,
    Offset Function(GridPosition) centreOf,
  ) {
    final selection = controller.selection;
    if (selection.length < 2) {
      // Single-cell press: just a soft dot so the touch is acknowledged.
      if (selection.length == 1) {
        canvas.drawCircle(
          centreOf(selection.first),
          cell * 0.42,
          Paint()..color = accent.withValues(alpha: 0.35),
        );
      }
      return;
    }

    final start = centreOf(selection.first);
    final end = centreOf(selection.last);

    // Glow beneath, then the ribbon itself.
    canvas
      ..drawLine(
        start,
        end,
        Paint()
          ..color = accent.withValues(alpha: 0.28)
          ..strokeWidth = cell * 1.02
          ..strokeCap = StrokeCap.round,
      )
      ..drawLine(
        start,
        end,
        Paint()
          ..color = accent.withValues(alpha: highContrast ? 0.98 : 0.85)
          ..strokeWidth = cell * 0.80
          ..strokeCap = StrokeCap.round,
      );
  }

  void _paintLetters(
    Canvas canvas,
    double cell,
    Offset origin,
    Offset Function(GridPosition) centreOf,
  ) {
    final puzzle = controller.puzzle;
    final fontSize = cell * (largeLetters ? 0.56 : 0.46);

    final selectionSet = controller.selection.toSet();
    final solved = controller.solvedCells;
    final dimmed = controller.dimmedCells;
    final hinted = controller.hintedCells;

    for (var r = 0; r < puzzle.rows; r++) {
      for (var c = 0; c < puzzle.cols; c++) {
        final position = GridPosition(r, c);
        final letter = puzzle.grid[r][c];

        final isSolved = solved.containsKey(position);
        final isSelected = selectionSet.contains(position);
        final isDimmed = dimmed.contains(position);
        final isHinted = hinted.contains(position);

        // Colour priority: selected/solved letters sit on a coloured ribbon
        // and must be white; dimmed clutter fades back; everything else is
        // normal body colour.
        final Color color;
        if (isSelected || isSolved) {
          color = Colors.white;
        } else if (isDimmed) {
          color = mutedLetterColor.withValues(alpha: 0.22);
        } else {
          color = letterColor;
        }

        // Hint halo — pulses so the eye is drawn to it.
        if (isHinted && !isSolved) {
          final pulse = 0.35 + 0.35 * hintPulse;
          canvas.drawCircle(
            centreOf(position),
            cell * 0.40,
            Paint()..color = AppPalette.amber.withValues(alpha: pulse),
          );
        }

        _drawText(canvas, letter, centreOf(position), fontSize, color);
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset centre,
    double fontSize,
    Color color,
  ) {
    // Round the size so tiny sub-pixel differences do not thrash the cache.
    final key = '$text|${fontSize.toStringAsFixed(1)}|${color.toARGB32()}';
    final painter = textCache.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: AppTypography.gridLetter(fontSize, color),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
    });

    painter.paint(
      canvas,
      centre - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_BoardPainter old) => true; // driven by AnimatedBuilder
}
