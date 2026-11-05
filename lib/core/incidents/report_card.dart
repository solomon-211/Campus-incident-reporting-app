import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/incident.dart';
import '../extensions.dart';
import '../widgets/animations.dart';
import 'incident_thumbnail.dart';
import 'status_chip.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.incident,
    required this.onTap,
    this.showPriority = false,
  });

  final Incident incident;
  final VoidCallback onTap;

  /// Staff see priority and "me too" counts on each card.
  final bool showPriority;

  @override
  Widget build(BuildContext context) {
    final meta = Theme.of(context).textTheme.bodySmall;
    return Pressable(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: incident.status.color, width: 4),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(10, 12, 12, 12),
            child: Row(
              children: [
                IncidentThumbnail(incident),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        incident.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: meta,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Meta(
                            icon: Icons.calendar_today_outlined,
                            text: incident.createdAtOrNow.timeAgo(),
                          ),
                          if (showPriority)
                            _Meta(
                              icon: Icons.flag_outlined,
                              text: incident.priority.label,
                              color: incident.priority.color,
                            ),
                          if (incident.upvoteCount > 0)
                            _Meta(
                              icon: Icons.people_outline_rounded,
                              text: '${incident.upvoteCount} me too',
                            ),
                          if (incident.hasPendingWrites)
                            const _Meta(
                              icon: Icons.cloud_upload_outlined,
                              text: 'Pending sync',
                              color: AppColors.accent,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(incident.status, dense: true),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: c),
          ),
        ),
      ],
    );
  }
}
