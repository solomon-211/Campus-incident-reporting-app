import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/hero_header.dart';
import '../../../core/incidents/incident_filters.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../../core/incidents/incident_list_sliver.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/incident.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../cubit/staff_cubit.dart';
import '../widgets/staff_filter_sheet.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.currentUser);
    if (user == null) return const SizedBox.shrink();
    final cubit = context.read<StaffCubit>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: cubit.refresh,
        child: BlocBuilder<StaffCubit, StaffState>(
          builder: (context, state) {
            final filtered = state.filtered;
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(user: user, state: state),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverList.list(
                    children: [
                      _Toolbar(state: state),
                      const SizedBox(height: 14),
                      StatusTabs(
                        selected: state.statusFilter,
                        onSelected: cubit.setStatusFilter,
                      ),
                      const SizedBox(height: 16),
                      _QueueHeading(state: state, shown: filtered.length),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                IncidentListSliver(
                  state: state,
                  showPriority: true,
                  onOpen: (incident) =>
                      context.push('/staff/incident/${incident.id}'),
                  whenNoReports: const EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No reports yet',
                    message: 'New reports from students will appear here.',
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

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.state});

  final AppUser user;
  final StaffState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StaffCubit>();
    final newCount = state.newReportCount(user.notificationsSeenAt);
    final muted = Colors.white.withValues(alpha: 0.7);

    return HeroHeader(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/staff/profile'),
                child: UserAvatar(user, radius: 22, ring: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff Dashboard',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Hello, ${user.firstName}!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              NotificationBell(
                count: newCount,
                onPressed: () {
                  context.read<AuthCubit>().markNotificationsSeen();
                  cubit.setStatusFilter(IncidentStatus.submitted);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            state.count(IncidentStatus.submitted) == 0
                ? 'You\'re all caught up.'
                : '${state.count(IncidentStatus.submitted)} reports are '
                      'waiting for review.',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Glass(
            borderRadius: BorderRadius.circular(16),
            tint: Colors.white,
            opacity: 0.08,
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    _Metric(
                      value: state.count(IncidentStatus.submitted),
                      label: 'Waiting',
                      color: AppColors.accent,
                      selected: state.statusFilter == IncidentStatus.submitted,
                      onTap: () => _toggle(cubit, IncidentStatus.submitted),
                    ),
                    const _Divider(),
                    _Metric(
                      value: state.count(IncidentStatus.inProgress),
                      label: 'In progress',
                      color: Colors.white,
                      selected: state.statusFilter == IncidentStatus.inProgress,
                      onTap: () => _toggle(cubit, IncidentStatus.inProgress),
                    ),
                    const _Divider(),
                    _Metric(
                      value: state.count(IncidentStatus.resolved),
                      label: 'Resolved',
                      color: const Color(0xFF7BD4A0),
                      selected: state.statusFilter == IncidentStatus.resolved,
                      onTap: () => _toggle(cubit, IncidentStatus.resolved),
                    ),
                    const _Divider(),
                    _Metric(
                      value: state.urgentCount,
                      label: 'Urgent',
                      color: const Color(0xFFFF8A80),
                      selected: state.sort == StaffSort.priority,
                      onTap: () => cubit
                        ..setStatusFilter(null)
                        ..setSort(StaffSort.priority),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(StaffCubit cubit, IncidentStatus status) =>
      cubit.setStatusFilter(state.statusFilter == status ? null : status);
}

/// One figure in the header's overview panel; tapping it filters the queue.
class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 24,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: selected ? 1 : 0.7),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 20 : 0,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.14),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.state});

  final StaffState state;

  @override
  Widget build(BuildContext context) {
    final active = state.activeFilterCount;
    return Row(
      children: [
        Expanded(
          child: SearchField(
            initialValue: state.query,
            onChanged: context.read<StaffCubit>().search,
          ),
        ),
        const SizedBox(width: 10),
        Badge(
          isLabelVisible: active > 0,
          backgroundColor: AppColors.accent,
          label: Text('$active'),
          child: Material(
            color: active > 0 ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => showStaffFilterSheet(context),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active > 0 ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: active > 0 ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "12 reports · Newest first", plus the category in use, if any.
class _QueueHeading extends StatelessWidget {
  const _QueueHeading({required this.state, required this.shown});

  final StaffState state;
  final int shown;

  @override
  Widget build(BuildContext context) {
    final category = state.categoryFilter;
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: shown == 1 ? '1 report' : '$shown reports',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextSpan(
                  text: '  ·  ${state.sort.label}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (category != null)
          InputChip(
            avatar: Icon(category.icon, size: 16),
            label: Text(category.label),
            onDeleted: () => context.read<StaffCubit>().setCategoryFilter(null),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
