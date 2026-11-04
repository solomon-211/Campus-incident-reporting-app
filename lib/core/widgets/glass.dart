import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted-glass panel: blurs whatever is behind it and tints it white.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.blur = 18,
    this.opacity = 0.72,
    this.tint = Colors.white,
    this.border,
    this.shadow = false,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double blur;

  /// How much [tint] is laid over the blur (0 = clear, 1 = solid).
  final double opacity;
  final Color tint;
  final BoxBorder? border;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tint.withValues(alpha: opacity),
              borderRadius: borderRadius,
              border:
                  border ??
                  Border.all(color: Colors.white.withValues(alpha: 0.6)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
