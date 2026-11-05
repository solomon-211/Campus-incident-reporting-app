import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../core/load_status.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/hero_header.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../../core/widgets/loading_list.dart';
import '../../../core/incidents/report_card.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/incident.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../reports/cubit/my_reports_cubit.dart';
import '../../../app/student_shell.dart';
import '../widgets/report_summary.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Opens My Reports with the given status tab selected.
  void _openReports(BuildContext context, IncidentStatus? status) {
    context.read<MyReportsCubit>()
      ..search('')
      ..setStatusFilter(status);
    context.go('/reports');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.currentUser);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: context.read<MyReportsCubit>().refresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: StudentShell.bottomClearance),
          children: [
            _Header(user: user),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FadeSlideIn(child: _ReportCard()),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Report Summary',
                    onSeeAll: () => _openReports(context, null),
                  ),
                  BlocBuilder<MyReportsCubit, MyReportsState>(
                    builder: (context, state) => ReportSummary(
                      state: state,
                      onOpen: (status) => _openReports(context, status),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Recent Reports',
                    onSeeAll: () => _openReports(context, null),
                  ),
                  BlocBuilder<MyReportsCubit, MyReportsState>(
                    builder: (context, state) => _RecentReports(state: state),
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

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return HeroHeader(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user.firstName}!',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<MyReportsCubit, MyReportsState>(
            builder: (context, state) => NotificationBell(
              count: state.unreadCount(user.notificationsSeenAt),
              onPressed: () => context.go('/home/notifications'),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: UserAvatar(user, radius: 22, ring: true),
          ),
        ],
      ),
    );
  }
}

/// Primary call to action, with shortcuts that open the form with a
/// category already chosen.
class _ReportCard extends StatelessWidget {
  const _ReportCard();

  @override
  Widget build(BuildContext context) {
    const inset = EdgeInsets.symmetric(horizontal: 20);
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.only(top: 20, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: inset,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Spotted a problem on campus?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Leaks, broken lights, safety hazards: report it and '
                  'follow the fix.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.push('/report'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Report an Issue'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: inset,
              scrollDirection: Axis.horizontal,
              itemCount: IncidentCategory.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final category = IncidentCategory.values[i];
                return ActionChip(
                  avatar: Icon(
                    category.icon,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(category.label),
                  labelStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppColors.background,
                  onPressed: () =>
                      context.push('/report?category=${category.name}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentReports extends StatelessWidget {
  const _RecentReports({required this.state});

  final MyReportsState state;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case LoadStatus.loading:
        return const LoadingList(count: 3, shrinkWrap: true);
      case LoadStatus.failure:
        return EmptyState.loadFailed(state.errorMessage);
      case LoadStatus.loaded:
        if (state.all.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No reports yet',
            message: 'Reports you submit will show up here.',
          );
        }
        return Column(
          children: [
            for (final (i, incident) in state.all.take(3).indexed)
              FadeSlideIn(
                key: ValueKey(incident.id),
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ReportCard(
                    incident: incident,
                    onTap: () => context.push('/incident/${incident.id}'),
                  ),
                ),
              ),
          ],
        );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }
}
