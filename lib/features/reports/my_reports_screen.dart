import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/extensions.dart';
import '../../core/load_status.dart';
import '../../core/widgets/animations.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/incident_filters.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/report_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/models/incident.dart';
import '../auth/cubit/auth_cubit.dart';
import '../home/student_shell.dart';
import 'cubit/incidents_cubit.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.currentUser);
    if (user == null) return const SizedBox.shrink();
    final cubit = context.read<IncidentsCubit>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('My Reports'),
        actions: [
          BlocBuilder<IncidentsCubit, IncidentsState>(
            buildWhen: (a, b) => a.categoryFilter != b.categoryFilter,
            builder: (context, state) => CategoryFilterButton(
              selected: state.categoryFilter,
              onSelected: cubit.setCategoryFilter,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: cubit.refresh,
        child: BlocBuilder<IncidentsCubit, IncidentsState>(
          builder: (context, state) {
            final filtered = state.filtered;
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  sliver: SliverList.list(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.primarySoft],
                          ),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              UserAvatar(user, radius: 30, ring: true),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            user.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const _RoleBadge('Student'),
                                      ],
                                    ),
                                    if (user.program.isNotEmpty)
                                      _InfoLine(
                                        Icons.school_outlined,
                                        user.program,
                                      ),
                                    if (user.campus.isNotEmpty)
                                      _InfoLine(
                                        Icons.location_on_outlined,
                                        user.campus,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Icons.description_outlined,
                              value: state.all.length,
                              label: 'Total Reports',
                              color: AppColors.primary,
                              background: AppColors.primaryTint,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              icon: IncidentStatus.inProgress.icon,
                              value: state.count(IncidentStatus.inProgress),
                              label: 'In Progress',
                              color: IncidentStatus.inProgress.color,
                              background: IncidentStatus.inProgress.background,
                            ),
                          ),
                          Expanded(
                            child: StatCard(
                              icon: IncidentStatus.resolved.icon,
                              value: state.count(IncidentStatus.resolved),
                              label: 'Resolved',
                              color: IncidentStatus.resolved.color,
                              background: IncidentStatus.resolved.background,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      StatusTabs(
                        selected: state.statusFilter,
                        onSelected: cubit.setStatusFilter,
                      ),
                      const SizedBox(height: 12),
                      SearchField(
                        initialValue: state.query,
                        onChanged: cubit.search,
                      ),
                      if (state.categoryFilter != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InputChip(
                            avatar: Icon(state.categoryFilter!.icon, size: 16),
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
                      icon: Icons.cloud_off_rounded,
                      title: state.errorMessage ?? 'Something went wrong',
                      message: 'Pull down to try again.',
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: state.all.isEmpty
                        ? EmptyState(
                            icon: Icons.inbox_outlined,
                            title: 'No reports yet',
                            message: 'Reports you submit will appear here.',
                            action: FilledButton(
                              onPressed: () => context.push('/report'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(200, 50),
                              ),
                              child: const Text('Report an issue'),
                            ),
                          )
                        : const EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No matching reports',
                            message: 'Try a different search or filter.',
                          ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      StudentShell.bottomClearance,
                    ),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => FadeSlideIn(
                        key: ValueKey(filtered[i].id),
                        index: i,
                        child: ReportCard(
                          incident: filtered[i],
                          onTap: () =>
                              context.push('/incident/${filtered[i].id}'),
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

class _RoleBadge extends StatelessWidget {
  const _RoleBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
