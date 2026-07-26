import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../state/game_session_controller.dart';

/// The list of words still to find.
///
/// Found words are **kept in place** and struck through rather than removed:
/// a shrinking list would make the panel jump around mid-game, and seeing what
/// you have already found is part of the satisfaction.
///
/// The panel wraps into as many rows as it needs and scrolls if the level has
/// a lot of long words, so it never squeezes the board.
class WordListPanel extends StatelessWidget {
  const WordListPanel({
    super.key,
    required this.controller,
    required this.maxHeight,
  });

  final GameSessionController controller;
  final double maxHeight;

  /// Mirrors the ribbon palette in `PuzzleBoard` so a word's chip and its
  /// ribbon on the board share a colour.
  static const _palette = [
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
  Widget build(BuildContext context) {
    if (!controller.isReady) return const SizedBox.shrink();

    final words = controller.puzzle.placedWords;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final placed in words)
              _WordChip(
                word: placed.word,
                found: controller.foundWords
                    .where((f) => f.placed.word == placed.word)
                    .firstOrNull,
              ),
          ],
        ),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.word, required this.found});

  final String word;
  final FoundWord? found;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFound = found != null;
    final color = isFound
        ? WordListPanel._palette[
            found!.orderFound % WordListPanel._palette.length]
        : null;

    return AnimatedContainer(
      duration: AppDurations.normal,
      curve: AppCurves.enter,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: isFound
            ? color!.withValues(alpha: 0.18)
            : theme.colorScheme.surfaceContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: isFound
              ? color!.withValues(alpha: 0.55)
              : theme.colorScheme.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFound) ...[
            Icon(
              // Distinguish "you found it" from "a hint found it" — honest
              // feedback, and it makes hint-free runs feel earned.
              found!.viaHint
                  ? Icons.auto_fix_high_rounded
                  : Icons.check_rounded,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            word,
            style: AppTypography.numeric(
              13.5,
              isFound ? color! : theme.colorScheme.onSurface,
              FontWeight.w700,
            ).copyWith(
              decoration: isFound ? TextDecoration.lineThrough : null,
              decorationColor: color,
              decorationThickness: 2,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Toast that flies up when a word is found.
class FoundWordToast extends StatelessWidget {
  const FoundWordToast({super.key, required this.found});

  final FoundWord? found;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: AppDurations.normal,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.6),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: AppCurves.spring),
          ),
          child: child,
        ),
      ),
      child: found == null
          ? const SizedBox(height: 30)
          : Container(
              // Key on the word so each new find re-triggers the switcher.
              key: ValueKey(found!.placed.word + found!.orderFound.toString()),
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppGradients.discovery,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                found!.viaHint
                    ? '${found!.placed.word} revealed'
                    : 'Nice! ${found!.placed.word}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}
