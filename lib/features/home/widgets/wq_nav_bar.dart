import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';

/// A navigation destination.
class NavItem {
  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// When non-null and > 0, draws an attention dot (used for "daily ready").
  final int? badgeCount;
}

/// The app's bottom navigation.
///
/// Rather than Material's default, this uses a **sliding pill** that animates
/// under the active item. The pill is a single positioned widget, so the
/// transition is continuous instead of four independent fades — which is what
/// makes it read as one control rather than four buttons.
class WqNavBar extends StatelessWidget {
  const WqNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        // Respect the gesture bar, but keep a minimum breathing gap.
        bottom: bottomInset > 0 ? bottomInset * 0.6 + 6 : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / items.length;

          return SizedBox(
            height: 58,
            child: Stack(
              children: [
                // Sliding highlight pill.
                AnimatedPositioned(
                  duration: AppDurations.normal,
                  curve: AppCurves.emphasised,
                  left: itemWidth * currentIndex,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Center(
                    child: Container(
                      width: itemWidth - 14,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.16),
                            theme.colorScheme.secondary.withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                  ),
                ),

                Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavButton(
                          item: items[i],
                          selected: i == currentIndex,
                          onTap: () => onSelected(i),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // The icon lifts slightly and swaps to its filled variant when
                // selected — two cues for the price of one animation.
                AnimatedSlide(
                  duration: AppDurations.normal,
                  curve: AppCurves.spring,
                  offset: Offset(0, selected ? -0.08 : 0),
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    size: 23,
                    color: color,
                  ),
                ),
                if ((item.badgeCount ?? 0) > 0)
                  Positioned(
                    right: -4,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppPalette.coral,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: AppDurations.normal,
              style: theme.textTheme.labelSmall!.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10.5,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
