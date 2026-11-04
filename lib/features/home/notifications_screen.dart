import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/extensions.dart';
import '../../core/load_status.dart';
import '../../core/widgets/animations.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../data/models/incident.dart';
import '../auth/cubit/auth_cubit.dart';
import '../reports/cubit/incidents_cubit.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  /// Captured on open so updates stay highlighted while the screen is shown,
  /// even though we mark them as seen straight away.
  DateTime? _seenBefore;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>();
    _seenBefore = auth.currentUser?.notificationsSeenAt;
    auth.markNotificationsSeen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: BlocBuilder<IncidentsCubit, IncidentsState>(
        builder: (context, state) {
          if (state.status == LoadStatus.loading) {
            return const LoadingList();
          }
          final items = state.notifications;
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No updates yet',
              message:
                  "When staff update one of your reports, you'll see it here.",
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => FadeSlideIn(
              key: ValueKey(items[i].id),
              index: i,
              child: _NotificationTile(
                incident: items[i],
                unread:
                    _seenBefore == null ||
                    items[i].updatedAt!.isAfter(_seenBefore!),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.incident, required this.unread});

  final Incident incident;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final status = incident.status;
    final note = incident.lastNote;
    return Card(
      color: unread ? AppColors.primaryTint : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/incident/${incident.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: status.background,
                child: Icon(status.icon, color: status.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: incident.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: ' is now '),
                          TextSpan(
                            text: status.label,
                            style: TextStyle(
                              color: status.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (note != null && note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '"$note"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      incident.updatedAt!.timeAgo(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (unread)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
