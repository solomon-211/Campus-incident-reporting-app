import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'animations.dart';

/// Summary card. With [total] set it also shows [value]'s share of it.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
    this.total,
    this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color color;

  final Color background;

  /// When set, a progress bar shows [value] as a share of [total].
  final int? total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final share = total == null || total == 0 ? 0.0 : value / total!;
    return Pressable(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.soft,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 19),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (total != null) ...[
                    const SizedBox(height: 10),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: share),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: v,
                                minHeight: 5,
                                color: color,
                                backgroundColor: color.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(v * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
