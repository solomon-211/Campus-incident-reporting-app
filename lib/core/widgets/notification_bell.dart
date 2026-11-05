import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'glass.dart';

/// Frosted bell for dark headers, with an orange badge showing [count].
class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: BorderRadius.circular(24),
      tint: Colors.white,
      opacity: 0.12,
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      child: IconButton(
        tooltip: count == 0 ? 'Notifications' : '$count new',
        onPressed: onPressed,
        icon: Badge(
          isLabelVisible: count > 0,
          backgroundColor: AppColors.accent,
          label: Text('$count'),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
