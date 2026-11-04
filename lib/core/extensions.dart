import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/theme.dart';
import '../data/models/incident.dart';
import 'widgets/glass_snack_bar.dart';

extension DateTimeX on DateTime {
  /// "Just now", "5 min ago", "2 hours ago", "3 days ago", then a date.
  String timeAgo([DateTime? now]) {
    final diff = (now ?? DateTime.now()).difference(this);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    }
    if (diff.inDays < 7) {
      return diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
    }
    return DateFormat('MMM d, y').format(this);
  }

  /// "Oct 15, 2026 at 10:24 AM"
  String get fullDateTime => DateFormat("MMM d, y 'at' h:mm a").format(this);

  /// "Oct 15, 10:24 AM"
  String get shortDateTime => DateFormat('MMM d, h:mm a').format(this);
}

extension IncidentStatusUi on IncidentStatus {
  Color get color => switch (this) {
    IncidentStatus.submitted => AppColors.accent,
    IncidentStatus.inProgress => AppColors.primary,
    IncidentStatus.resolved => AppColors.green,
    IncidentStatus.rejected => AppColors.red,
  };

  Color get background => switch (this) {
    IncidentStatus.submitted => AppColors.accentTint,
    IncidentStatus.inProgress => AppColors.primaryTint,
    IncidentStatus.resolved => AppColors.greenTint,
    IncidentStatus.rejected => AppColors.redTint,
  };

  IconData get icon => switch (this) {
    IncidentStatus.submitted => Icons.hourglass_empty_rounded,
    IncidentStatus.inProgress => Icons.schedule_rounded,
    IncidentStatus.resolved => Icons.check_circle_outline_rounded,
    IncidentStatus.rejected => Icons.block_rounded,
  };
}

extension IncidentCategoryUi on IncidentCategory {
  IconData get icon => switch (this) {
    IncidentCategory.facilities => Icons.apartment_rounded,
    IncidentCategory.water => Icons.water_drop_outlined,
    IncidentCategory.electricity => Icons.bolt_rounded,
    IncidentCategory.safety => Icons.shield_outlined,
    IncidentCategory.sanitation => Icons.delete_outline_rounded,
    IncidentCategory.furniture => Icons.chair_outlined,
  };
}

extension IncidentPriorityUi on IncidentPriority {
  Color get color => switch (this) {
    IncidentPriority.low => AppColors.textSecondary,
    IncidentPriority.medium => AppColors.accent,
    IncidentPriority.high => AppColors.red,
  };
}

extension ContextX on BuildContext {
  /// Frosted-glass snackbar. Success by default; pass [error] or [info].
  void showSnack(String message, {bool error = false, bool info = false}) {
    const duration = Duration(seconds: 3);
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          padding: EdgeInsets.zero,
          content: GlassSnackContent(
            message: message,
            kind: error
                ? SnackKind.error
                : info
                ? SnackKind.info
                : SnackKind.success,
            duration: duration,
          ),
        ),
      );
  }
}
