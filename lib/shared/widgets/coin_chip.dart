import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';

/// A number that counts up (or down) to its new value instead of snapping.
///
/// Tweening the *value* rather than cross-fading the text is what makes a
/// coin reward feel earned — the player watches the number climb.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 650),
    this.prefix = '',
  });

  final int value;
  final TextStyle style;
  final Duration duration;
  final String prefix;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: value.toDouble(), end: value.toDouble()),
        duration: duration,
        curve: AppCurves.enter,
        builder: (context, animated, _) =>
            Text('$prefix${animated.round()}', style: style),
      );
}

/// The coin balance pill shown in headers.
///
/// Tapping it opens the shop, so the player always has a one-tap route to more
/// coins from anywhere they can see their balance.
class CoinChip extends StatefulWidget {
  const CoinChip({
    super.key,
    required this.coins,
    this.onTap,
    this.compact = false,
  });

  final int coins;
  final VoidCallback? onTap;
  final bool compact;

  @override
  State<CoinChip> createState() => _CoinChipState();
}

class _CoinChipState extends State<CoinChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppDurations.slow,
  );

  late int _displayed = widget.coins;

  @override
  void didUpdateWidget(CoinChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only celebrate *gains* — spending coins should not feel triumphant.
    if (widget.coins > oldWidget.coins) {
      _pulse.forward(from: 0);
    }
    _displayed = widget.coins;
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$_displayed coins',
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => Transform.scale(
            scale: 1 + 0.12 * Curves.elasticOut.transform(_pulse.value) *
                (1 - _pulse.value),
            child: child,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? AppSpacing.sm : AppSpacing.md,
              vertical: widget.compact ? 5 : 7,
            ),
            decoration: BoxDecoration(
              gradient: AppGradients.reward,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.amber.withValues(alpha: 0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on_rounded,
                  size: widget.compact ? 15 : 18,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
                const SizedBox(width: 5),
                AnimatedCounter(
                  value: widget.coins,
                  style: AppTypography.numeric(
                    widget.compact ? 13 : 15,
                    Colors.white,
                  ),
                ),
                if (widget.onTap != null) ...[
                  const SizedBox(width: 3),
                  Icon(
                    Icons.add_circle_rounded,
                    size: widget.compact ? 13 : 15,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small labelled statistic used across the home, profile and result screens.
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: tint),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.numeric(17, theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
