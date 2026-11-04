import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../data/models/incident.dart';
import '../../../data/models/status_update.dart';

/// Horizontal three-step progress: Submitted → In Progress → Resolved
/// (or Rejected).
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({
    super.key,
    required this.current,
    required this.reachedAt,
  });

  final IncidentStatus current;
  final DateTime? Function(IncidentStatus) reachedAt;

  @override
  Widget build(BuildContext context) {
    final last = current == IncidentStatus.rejected
        ? IncidentStatus.rejected
        : IncidentStatus.resolved;
    final steps = [IncidentStatus.submitted, IncidentStatus.inProgress, last];
    final currentIndex = switch (current) {
      IncidentStatus.submitted => 0,
      IncidentStatus.inProgress => 1,
      IncidentStatus.resolved || IncidentStatus.rejected => 2,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: _Step(
              status: steps[i],
              done: i <= currentIndex,
              isCurrent: i == currentIndex,
              date: reachedAt(steps[i]),
              connectLeft: i > 0,
              leftDone: i <= currentIndex,
              connectRight: i < steps.length - 1,
              rightDone: i < currentIndex,
            ),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.status,
    required this.done,
    required this.isCurrent,
    required this.date,
    required this.connectLeft,
    required this.leftDone,
    required this.connectRight,
    required this.rightDone,
  });

  final IncidentStatus status;
  final bool done;
  final bool isCurrent;
  final DateTime? date;
  final bool connectLeft;
  final bool leftDone;
  final bool connectRight;
  final bool rightDone;

  @override
  Widget build(BuildContext context) {
    final color = done ? status.color : AppColors.border;
    Widget line(bool visible, bool active) => Expanded(
      child: Container(
        height: 3,
        color: !visible
            ? Colors.transparent
            : active
            ? AppColors.primary
            : AppColors.border,
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            line(connectLeft, leftDone),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: done ? color : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                status == IncidentStatus.rejected
                    ? Icons.close_rounded
                    : done
                    ? Icons.check_rounded
                    : Icons.circle,
                size: done ? 18 : 8,
                color: done ? Colors.white : AppColors.border,
              ),
            ),
            line(connectRight, rightDone),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          status.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: done ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          date != null ? date!.shortDateTime : (done ? '' : '—'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class UpdateHistory extends StatelessWidget {
  const UpdateHistory({super.key, required this.updates});

  final List<StatusUpdate> updates;

  @override
  Widget build(BuildContext context) {
    final newestFirst = updates.reversed.toList();
    return Column(
      children: [
        for (var i = 0; i < newestFirst.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: newestFirst[i].status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i < newestFirst.length - 1)
                      Expanded(
                        child: Container(width: 2, color: AppColors.border),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          newestFirst[i].status.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (newestFirst[i].note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(newestFirst[i].note),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            newestFirst[i].updatedByName,
                            if (newestFirst[i].timestamp != null)
                              newestFirst[i].timestamp!.fullDateTime,
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
