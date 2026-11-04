import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/extensions.dart';
import '../../core/load_status.dart';
import '../../core/widgets/animations.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/hero_header.dart';
import '../../core/widgets/incident_filters.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/report_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/models/incident.dart';
import '../auth/cubit/auth_cubit.dart';
import 'cubit/staff_cubit.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.currentUser);
    if (user == null) return const SizedBox.shrink();
    final cubit = context.read<StaffCubit>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        title: const Text('Staff Dashboard'),
        actions: [
          BlocBuilder<StaffCubit, StaffState>(
            buildWhen: (a, b) =>
                a.categoryFilter != b.categoryFilter || a.sort != b.sort,
            builder: (context, state) => Row(
              children: [
                PopupMenuButton<StaffSort>(
                  tooltip: 'Sort',
                  icon: const Icon(Icons.sort_rounded),
                  onSelected: cubit.setSort,
                  itemBuilder: (_) => [
                    for (final s in StaffSort.values)
                      CheckedPopupMenuItem(
                        value: s,
                        checked: state.sort == s,
                        child: Text(s.label),
                      ),
                  ],
                ),
                CategoryFilterButton(
                  selected: state.categoryFilter,
                  onSelected: cubit.setCategoryFilter,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: GestureDetector(
              onTap: () => context.push('/staff/profile'),
              child: UserAvatar(user, radius: 17, ring: true),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: cubit.refresh,
        child: BlocBuilder<StaffCubit, StaffState>(
          builder: (context, state) {
            final filtered = state.filtered;
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: HeroHeader(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 64),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${user.firstName}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.count(IncidentStatus.submitted)} new reports '
                          'are waiting for review.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  sliver: SliverList.list(
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -40),
                        child: Row(
                          spacing: 8,
                          children: [
                            for (final s in IncidentStatus.values)
                              Expanded(
                                child: StatCard(
                                  icon: s.icon,
                                  value: state.count(s),
                                  label: s.label,
                                  color: s.color,
                                  background: s.background,
                                  onTap: () => cubit.setStatusFilter(
                                    state.statusFilter == s ? null : s,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SearchField(
                        initialValue: state.query,
                        onChanged: cubit.search,
                      ),
                      const SizedBox(height: 12),
                      StatusTabs(
                        selected: state.statusFilter,
                        onSelected: cubit.setStatusFilter,
                        counts: state.counts,
                      ),
                      if (state.categoryFilter != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InputChip(
                            label: Text(state.categoryFilter!.label),
                            onDeleted: () => cubit.setCategoryFilter(null),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                if (state.status == LoadStatus.loading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: LoadingList(shrinkWrap: true),
                    ),
                  )
                else if (state.status == LoadStatus.failure)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.lock_outline_rounded,
                      title: state.errorMessage ?? 'Something went wrong',
                      message: 'Pull down to try again.',
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: state.all.isEmpty
                          ? Icons.celebration_outlined
                          : Icons.search_off_rounded,
                      title: state.all.isEmpty
                          ? 'No reports yet'
                          : 'No matching reports',
                      message: state.all.isEmpty
                          ? 'New reports from students will appear here.'
                          : 'Try a different search or filter.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => FadeSlideIn(
                        key: ValueKey(filtered[i].id),
                        index: i,
                        child: ReportCard(
                          incident: filtered[i],
                          showPriority: true,
                          onTap: () =>
                              context.push('/staff/incident/${filtered[i].id}'),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
