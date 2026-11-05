import 'package:flutter/material.dart';

import '../../data/models/incident.dart';
import '../load_status.dart';
import '../widgets/animations.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_list.dart';
import 'incident_list_cubit.dart';
import 'report_card.dart';

/// The list part of a report screen, as a sliver: shimmer while loading, an
/// error or empty message, or the filtered report cards.
class IncidentListSliver extends StatelessWidget {
  const IncidentListSliver({
    super.key,
    required this.state,
    required this.whenNoReports,
    required this.onOpen,
    this.showPriority = false,
    this.bottomPadding = 32,
  });

  final IncidentListState state;

  /// Shown when there are no reports at all (as opposed to none matching).
  final Widget whenNoReports;
  final ValueChanged<Incident> onOpen;
  final bool showPriority;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final reports = state.filtered;
    if (state.status == LoadStatus.loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: LoadingList(shrinkWrap: true),
        ),
      );
    }
    if (state.status == LoadStatus.failure || reports.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: state.status == LoadStatus.failure
            ? EmptyState.loadFailed(state.errorMessage)
            : state.all.isEmpty
            ? whenNoReports
            : const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matching reports',
                message: 'Try a different search or filter.',
              ),
      );
    }
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding),
      sliver: SliverList.separated(
        itemCount: reports.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => FadeSlideIn(
          key: ValueKey(reports[i].id),
          index: i,
          child: ReportCard(
            incident: reports[i],
            showPriority: showPriority,
            onTap: () => onOpen(reports[i]),
          ),
        ),
      ),
    );
  }
}
