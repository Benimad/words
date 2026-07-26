import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';

/// The app's primary button.
///
/// Two details do the heavy lifting:
///  * a **press-scale** (0.96) driven by the raw pointer, so the button reacts
///    the instant a finger lands rather than on tap-up, and
///  * a soft coloured **glow** under the gradient, which is what makes the
///    control read as "lit" against the aurora backdrop.
///
/// It stays a real button for accessibility: [Semantics] labels it, and the
/// 52dp minimum height clears the recommended touch-target size.
class WqButton extends StatefulWidget {
  const WqButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient,
    this.expand = true,
    this.height = 56,
    this.enabled = true,
    this.variant = WqButtonVariant.filled,
    this.badge,
  });

  /// Convenience constructor for the secondary (outlined) style.
  const WqButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.height = 56,
    this.enabled = true,
    this.badge,
  })  : gradient = null,
        variant = WqButtonVariant.outlined;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient? gradient;
  final bool expand;
  final double height;
  final bool enabled;
  final WqButtonVariant variant;

  /// Optional trailing chip, e.g. a hint's coin price.
  final Widget? badge;

  @override
  State<WqButton> createState() => _WqButtonState();
}

enum WqButtonVariant { filled, outlined, ghost }

class _WqButtonState extends State<WqButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: AppDurations.instant,
    lowerBound: 0,
    upperBound: 1,
  );

  bool get _isInteractive => widget.enabled && widget.onPressed != null;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (!_isInteractive) return;
    pressed ? _press.forward() : _press.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = widget.gradient ?? AppGradients.brand;
    final isFilled = widget.variant == WqButtonVariant.filled;

    return Semantics(
      button: true,
      enabled: _isInteractive,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _isInteractive ? widget.onPressed : null,
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, child) => Transform.scale(
            scale: 1 - (_press.value * 0.04),
            child: child,
          ),
          child: AnimatedOpacity(
            duration: AppDurations.fast,
            opacity: _isInteractive ? 1 : 0.45,
            child: Container(
              width: widget.expand ? double.infinity : null,
              height: widget.height,
              padding: EdgeInsets.symmetric(
                horizontal: widget.expand ? AppSpacing.lg : AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                gradient: isFilled ? gradient : null,
                color: switch (widget.variant) {
                  WqButtonVariant.filled => null,
                  WqButtonVariant.outlined => Colors.transparent,
                  WqButtonVariant.ghost =>
                    theme.colorScheme.surfaceContainerHigh,
                },
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: widget.variant == WqButtonVariant.outlined
                    ? Border.all(color: theme.colorScheme.outline, width: 1.6)
                    : null,
                boxShadow: isFilled && _isInteractive
                    ? [
                        BoxShadow(
                          // Tint the shadow with the button's own colour — a
                          // neutral grey shadow would look pasted-on here.
                          color: (gradient.colors[1]).withValues(alpha: 0.38),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                          spreadRadius: -4,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize:
                    widget.expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 20,
                      color: _foreground(theme, isFilled),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _foreground(theme, isFilled),
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                  ),
                  if (widget.badge != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    widget.badge!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _foreground(ThemeData theme, bool isFilled) => isFilled
      ? Colors.white
      : theme.colorScheme.onSurface;
}

/// Circular icon button used in headers and the in-game HUD.
class WqIconButton extends StatefulWidget {
  const WqIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 46,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  State<WqIconButton> createState() => _WqIconButtonState();
}

class _WqIconButtonState extends State<WqIconButton>
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final button = GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, child) => Transform.scale(
          scale: 1 - _press.value * 0.1,
          child: child,
        ),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.background ??
                theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Icon(
            widget.icon,
            size: widget.size * 0.46,
            color: widget.foreground ?? theme.colorScheme.onSurface,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: widget.tooltip,
      child: widget.tooltip == null
          ? button
          : Tooltip(message: widget.tooltip!, child: button),
    );
  }
}
