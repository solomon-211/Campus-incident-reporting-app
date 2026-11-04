import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'glass.dart';

enum SnackKind { success, error, info }

class GlassSnackContent extends StatelessWidget {
  const GlassSnackContent({
    super.key,
    required this.message,
    required this.kind,
    required this.duration,
  });

  final String message;
  final SnackKind kind;
  final Duration duration;

  Color get _color => switch (kind) {
    SnackKind.success => AppColors.green,
    SnackKind.error => AppColors.red,
    SnackKind.info => AppColors.primary,
  };

  IconData get _icon => switch (kind) {
    SnackKind.success => Icons.check_circle_rounded,
    SnackKind.error => Icons.error_rounded,
    SnackKind.info => Icons.info_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Glass(
        borderRadius: BorderRadius.circular(16),
        opacity: 0.78,
        shadow: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _color.withValues(alpha: 0.14),
                    child: Icon(_icon, color: _color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: duration,
              builder: (context, value, _) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: value,
                  child: Container(height: 3, color: _color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
