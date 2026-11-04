import 'package:flutter/material.dart';

/// Fades and slides its child up into place when first shown. Items in a list
/// pass their [index] so they arrive one after another.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  static const _motionMs = 420;

  // Stagger the first few items; later ones appear without extra delay. The
  // delay is part of the animation itself, so there's no timer to clean up.
  late final int _delayMs = 60 * widget.index.clamp(0, 6);

  late final _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _delayMs + _motionMs),
  )..forward();

  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _delayMs / (_delayMs + _motionMs),
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// Shrinks its child slightly while a finger is on it, so taps feel
/// responsive. Uses raw pointer events, so it never competes with the
/// child's own tap handling.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.scale = 0.97});

  final Widget child;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
