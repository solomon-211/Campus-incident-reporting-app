import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../data/models/incident.dart';
import '../../reports/cubit/incidents_cubit.dart';

/// Home's report summary: an overview card with the resolution rate and a
/// status breakdown, above one card per status.
class ReportSummary extends StatelessWidget {
  const ReportSummary({super.key, required this.state, required this.onOpen});

  final IncidentsState state;
  final ValueChanged<IncidentStatus?> onOpen;

  @override
  Widget build(BuildContext context) {
    final total = state.all.length;
    return Column(
      children: [
        _OverviewCard(state: state, onTap: () => onOpen(null)),
        const SizedBox(height: 12),
        Row(
          spacing: 12,
          children: [
            for (final status in const [
              IncidentStatus.submitted,
              IncidentStatus.inProgress,
              IncidentStatus.resolved,
            ])
              Expanded(
                child: StatCard(
                  icon: status.icon,
                  value: state.count(status),
                  label: status.label,
                  color: status.color,
                  background: status.background,
                  total: total,
                  onTap: () => onOpen(status),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.state, required this.onTap});

  final IncidentsState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = state.all.length;
    final resolved = state.count(IncidentStatus.resolved);
    final rate = total == 0 ? 0.0 : resolved / total;
    final muted = Colors.white.withValues(alpha: 0.7);

    return Pressable(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primarySoft],
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your reports',
                              style: TextStyle(
                                color: muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$total',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                height: 1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              total == 0
                                  ? 'Nothing reported yet'
                                  : '$resolved of $total resolved',
                              style: TextStyle(color: muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      _ResolutionRing(rate: rate),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Glass(
                    borderRadius: BorderRadius.circular(16),
                    tint: Colors.white,
                    opacity: 0.1,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _StatusBreakdown(state: state),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResolutionRing extends StatelessWidget {
  const _ResolutionRing({required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: rate),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox.square(
        dimension: 76,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: v,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              color: AppColors.accent,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(rate * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'resolved',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  const _StatusBreakdown({required this.state});

  final IncidentsState state;

  // In Progress is ink, which wouldn't show on the dark card.
  static Color _barColor(IncidentStatus s) =>
      s == IncidentStatus.inProgress ? Colors.white : s.color;

  @override
  Widget build(BuildContext context) {
    final statuses = [
      for (final s in IncidentStatus.values)
        if (s != IncidentStatus.rejected || state.count(s) > 0) s,
    ];
    final total = state.all.length;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: total == 0
                ? ColoredBox(color: Colors.white.withValues(alpha: 0.15))
                : Row(
                    spacing: 2,
                    // Segments have no height of their own; fill the bar.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final s in statuses)
                        if (state.count(s) > 0)
                          Expanded(
                            flex: state.count(s),
                            child: ColoredBox(color: _barColor(s)),
                          ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final s in statuses)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _barColor(s),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${s.label} ${state.count(s)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
