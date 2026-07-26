import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/hint.dart';

/// The three hint buttons plus the "watch an ad for coins" affordance.
///
/// Buttons show their price at all times and grey out when unaffordable — the
/// player should never tap one and be surprised by a paywall dialog.
class HintBar extends StatelessWidget {
  const HintBar({
    super.key,
    required this.coins,
    required this.onHint,
    required this.onWatchAd,
    required this.rewardedAvailable,
    required this.enabled,
  });

  final int coins;
  final void Function(HintType) onHint;
  final VoidCallback onWatchAd;
  final bool rewardedAvailable;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final type in HintType.values) ...[
          Expanded(
            child: _HintButton(
              type: type,
              affordable: coins >= type.cost,
              enabled: enabled,
              onTap: () => onHint(type),
            ),
          ),
          if (type != HintType.values.last)
            const SizedBox(width: AppSpacing.sm),
        ],
        if (rewardedAvailable) ...[
          const SizedBox(width: AppSpacing.sm),
          _WatchAdButton(onTap: onWatchAd, enabled: enabled),
        ],
      ],
    );
  }
}

class _HintButton extends StatefulWidget {
  const _HintButton({
    required this.type,
    required this.affordable,
    required this.enabled,
    required this.onTap,
  });

  final HintType type;
  final bool affordable;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_HintButton> createState() => _HintButtonState();
}

class _HintButtonState extends State<_HintButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: AppDurations.instant,
  );

  bool get _active => widget.enabled;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dim = !widget.affordable || !_active;

    return Semantics(
      button: true,
      enabled: _active,
      label: '${widget.type.label}, ${widget.type.cost} coins',
      child: GestureDetector(
        onTapDown: _active ? (_) => _press.forward() : null,
        onTapUp: _active ? (_) => _press.reverse() : null,
        onTapCancel: () => _press.reverse(),
        onTap: _active ? widget.onTap : null,
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, child) => Transform.scale(
            scale: 1 - _press.value * 0.05,
            child: child,
          ),
          child: AnimatedOpacity(
            duration: AppDurations.fast,
            opacity: dim ? 0.5 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: 6,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer.withValues(alpha: .82),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.type.icon,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.type.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        size: 11,
                        color: AppPalette.amber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.type.cost}',
                        style: AppTypography.numeric(
                          11,
                          widget.affordable
                              ? AppPalette.amber
                              : theme.colorScheme.error,
                          FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WatchAdButton extends StatelessWidget {
  const _WatchAdButton({required this.onTap, required this.enabled});

  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Watch an ad for free coins',
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 62,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            gradient: AppGradients.reward,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.play_circle_fill_rounded,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(height: 5),
              Text(
                'Free\ncoins',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 9.5,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
