import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';

/// The standard content card: translucent fill over the aurora, hairline
/// border, generous radius.
///
/// Translucency (rather than an opaque fill) is deliberate — it lets the
/// animated backdrop show through just enough to tie every surface to the
/// same environment.
class WqCard extends StatelessWidget {
  const WqCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.gradient,
    this.borderColor,
    this.radius = AppRadii.lg,
    this.opacity = 0.72,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? borderColor;
  final double radius;
  final double opacity;

  /// Adds a soft drop shadow for cards that should sit above the page.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null
            ? theme.colorScheme.surfaceContainer.withValues(alpha: opacity)
            : null,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? theme.colorScheme.outline),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.35 : 0.07,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                  spreadRadius: -6,
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return _PressableCard(radius: radius, onTap: onTap!, child: content);
  }
}

/// Adds the app's standard press-scale to any card-shaped tap target.
class _PressableCard extends StatefulWidget {
  const _PressableCard({
    required this.child,
    required this.onTap,
    required this.radius,
  });

  final Widget child;
  final VoidCallback onTap;
  final double radius;

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: AppDurations.instant,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, child) => Transform.scale(
            scale: 1 - _press.value * 0.025,
            child: child,
          ),
          child: widget.child,
        ),
      );
}

/// A labelled, animated progress bar with a gradient fill.
class WqProgressBar extends StatelessWidget {
  const WqProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.gradient,
    this.backgroundColor,
    this.duration = AppDurations.slow,
  });

  /// 0-1.
  final double value;
  final double height;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(
            height: height,
            color: backgroundColor ??
                theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
            duration: duration,
            curve: AppCurves.enter,
            builder: (context, animated, _) => FractionallySizedBox(
              widthFactor: animated,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: gradient ??
                      LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular progress with a value in the middle. Used for achievements.
class WqProgressRing extends StatelessWidget {
  const WqProgressRing({
    super.key,
    required this.value,
    required this.size,
    required this.color,
    this.strokeWidth = 5,
    this.child,
  });

  final double value;
  final double size;
  final Color color;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
            duration: AppDurations.slow,
            curve: AppCurves.enter,
            builder: (context, animated, _) => SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: animated,
                strokeWidth: strokeWidth,
                strokeCap: StrokeCap.round,
                backgroundColor: theme.colorScheme.outline,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

/// Section heading with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!, style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

/// Star row used on level cards and the results screen.
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.stars,
    this.size = 16,
    this.total = 3,
    this.color,
    this.animate = false,
  });

  final int stars;
  final double size;
  final int total;
  final Color? color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = color ?? theme.colorScheme.tertiary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isFilled = i < stars;
        final star = Icon(
          isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: isFilled
              ? filled
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        );

        if (!animate || !isFilled) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: star,
          );
        }

        // Stars land one after another — the core beat of the results screen.
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 420 + i * 180),
            curve: Curves.elasticOut,
            builder: (context, t, child) => Transform.scale(
              scale: t.clamp(0.0, 1.4),
              child: child,
            ),
            child: star,
          ),
        );
      }),
    );
  }
}

/// Full-screen empty/error state with an icon, message and optional action.
class WqEmptyState extends StatelessWidget {
  const WqEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Monospaced-feeling countdown/elapsed readout for the game HUD.
class TimeReadout extends StatelessWidget {
  const TimeReadout({
    super.key,
    required this.duration,
    required this.color,
    this.size = 15,
  });

  final Duration duration;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return Text(
      '$minutes:${seconds.toString().padLeft(2, '0')}',
      style: AppTypography.numeric(size, color, FontWeight.w700),
    );
  }
}
