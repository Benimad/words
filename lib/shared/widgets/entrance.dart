import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Fades and slides a widget in once, on first build.
///
/// Staggering these (via [delay]) is the cheapest way to make a screen feel
/// authored rather than dumped: content arrives in reading order instead of
/// all at once. Keep total stagger under ~400ms or the screen feels slow.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppDurations.slow,
    this.offset = const Offset(0, 0.10),
    this.curve = AppCurves.enter,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Start offset as a fraction of the child's own size.
  final Offset offset;
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        // The screen may have been popped during the delay.
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: widget.offset, end: Offset.zero).animate(curved),
        child: widget.child,
      ),
    );
  }
}

/// Scales a widget in with a slight overshoot. Used for badges, medals and
/// anything that should feel like it "pops".
class PopIn extends StatefulWidget {
  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppDurations.slow,
    this.from = 0.6,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double from;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutBack.transform(_controller.value.clamp(0, 1));
        return Opacity(
          opacity: _controller.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: widget.from + (1 - widget.from) * t,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Gentle infinite "breathing" scale — draws the eye to a primary CTA without
/// the aggression of a bounce.
class Breathe extends StatefulWidget {
  const Breathe({
    super.key,
    required this.child,
    this.scale = 0.025,
    this.period = const Duration(milliseconds: 2600),
  });

  final Widget child;
  final double scale;
  final Duration period;

  @override
  State<Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<Breathe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: 1 +
              widget.scale *
                  Curves.easeInOut.transform(_controller.value),
          child: child,
        ),
        child: widget.child,
      );
}

/// A one-shot horizontal shake. Rebuilt whenever [trigger] changes, which is
/// how the board signals "that selection was wrong" without a controller ref.
class ShakeOnChange extends StatefulWidget {
  const ShakeOnChange({
    super.key,
    required this.child,
    required this.trigger,
    this.distance = 10,
  });

  final Widget child;

  /// Any value that changes when a shake should occur (typically a counter).
  final Object trigger;
  final double distance;

  @override
  State<ShakeOnChange> createState() => _ShakeOnChangeState();
}

class _ShakeOnChangeState extends State<ShakeOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(ShakeOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Damped sine: three oscillations that decay to nothing.
          final t = _controller.value;
          final decay = (1 - t) * (1 - t);
          // 3 full oscillations over the animation.
          final offset =
              widget.distance * decay * math.sin(t * 3 * 2 * math.pi);
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: widget.child,
      );
}
