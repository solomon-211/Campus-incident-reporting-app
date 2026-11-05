import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/incidents/incident_thumbnail.dart';
import '../../../core/incidents/status_chip.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/incident.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../cubit/incident_detail_cubit.dart';
import '../widgets/photo_viewer.dart';
import '../widgets/status_timeline.dart';

class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({super.key, this.bottomAction});

  /// Extra action pinned to the bottom (staff pass the "Update status"
  /// button here).
  final Widget? bottomAction;

  Future<void> _confirmDelete(BuildContext context, bool isStaff) async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Delete this report?',
      message: isStaff
          ? 'It will be removed for everyone, including the reporter.'
          : 'You can only withdraw a report before staff start on it. '
                'This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) return;
    final error = await context.read<IncidentDetailCubit>().delete();
    if (!context.mounted) return;
    if (error != null) {
      context.showSnack(error, error: true);
      return;
    }
    context.showSnack('Report deleted');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewer = context.select((AuthCubit c) => c.currentUser);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        actions: [
          BlocBuilder<IncidentDetailCubit, IncidentDetailState>(
            buildWhen: (a, b) => a.incident != b.incident,
            builder: (context, state) {
              final incident = state.incident;
              if (incident == null ||
                  viewer == null ||
                  !incident.canBeDeletedBy(
                    uid: viewer.uid,
                    isStaff: viewer.isStaff,
                  )) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'Delete report',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _confirmDelete(context, viewer.isStaff),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<IncidentDetailCubit, IncidentDetailState>(
        builder: (context, state) {
          switch (state.status) {
            case DetailStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case DetailStatus.notFound:
              return const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Report not found',
                message: 'It may have been removed.',
              );
            case DetailStatus.failure:
              return EmptyState(
                icon: Icons.cloud_off_rounded,
                title: state.errorMessage ?? 'Something went wrong',
                action: FilledButton.tonal(
                  onPressed: context.read<IncidentDetailCubit>().watch,
                  child: const Text('Retry'),
                ),
              );
            case DetailStatus.loaded:
              if (viewer == null) return const SizedBox.shrink();
              return _DetailBody(
                state: state,
                incident: state.incident!,
                viewer: viewer,
              );
          }
        },
      ),
      bottomNavigationBar: bottomAction == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: bottomAction,
              ),
            ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.state,
    required this.incident,
    required this.viewer,
  });

  final IncidentDetailState state;
  final Incident incident;
  final AppUser viewer;

  @override
  Widget build(BuildContext context) {
    final meta = Theme.of(context).textTheme.bodySmall;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IncidentThumbnail(incident, size: 72),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            incident.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(incident.location, style: meta),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              StatusChip(incident.status),
                              if (incident.hasPendingWrites)
                                const _Tag(
                                  icon: Icons.cloud_upload_outlined,
                                  label: 'Pending sync',
                                  color: AppColors.accent,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.border),
                _MetaRow(
                  icon: Icons.calendar_today_outlined,
                  text: 'Submitted on ${incident.createdAtOrNow.fullDateTime}',
                ),
                _MetaRow(
                  icon: Icons.person_outline_rounded,
                  text: 'Reported by ${incident.reporterNameFor(viewer.uid)}',
                ),
                _MetaRow(
                  icon: incident.category.icon,
                  text: incident.category.label,
                ),
                if (viewer.isStaff)
                  _MetaRow(
                    icon: Icons.flag_outlined,
                    text: '${incident.priority.label} priority',
                    color: incident.priority.color,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _MeToo(incident: incident, viewer: viewer),
        const SizedBox(height: 20),
        const _SectionTitle('Status Timeline'),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: StatusTimeline(
              current: incident.status,
              reachedAt: state.reachedAt,
            ),
          ),
        ),
        if (state.timeline.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: UpdateHistory(updates: state.timeline),
            ),
          ),
        ],
        const SizedBox(height: 20),
        const _SectionTitle('Description'),
        Text(incident.description, style: const TextStyle(height: 1.5)),
        if (incident.photoCount > 0) ...[
          const SizedBox(height: 20),
          _SectionTitle(
            incident.photoCount == 1 ? 'Attached Photo' : 'Attached Photos',
          ),
          if (state.photos.isNotEmpty)
            _Photos(photos: state.photos)
          else if (state.photosLoading)
            Container(
              height: 200,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const CircularProgressIndicator(),
            )
          else
            Text(
              'Photos could not be loaded.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ],
    );
  }
}

/// "Me too" upvote for other students; a count for everyone else.
class _MeToo extends StatelessWidget {
  const _MeToo({required this.incident, required this.viewer});

  final Incident incident;
  final AppUser viewer;

  @override
  Widget build(BuildContext context) {
    final count = incident.upvoteCount;
    final canVote = !viewer.isStaff && viewer.uid != incident.reporterId;

    if (!canVote) {
      if (count == 0) return const SizedBox.shrink();
      return _Tag(
        icon: Icons.people_outline_rounded,
        label: count == 1
            ? '1 other person reported this too'
            : '$count other people reported this too',
        color: AppColors.primary,
      );
    }

    final voted = incident.isUpvotedBy(viewer.uid);
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        backgroundColor: voted ? AppColors.primaryTint : null,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
        final error = await context.read<IncidentDetailCubit>().toggleUpvote(
          viewer.uid,
        );
        if (error != null && context.mounted) {
          context.showSnack(error, error: true);
        }
      },
      icon: Icon(
        voted ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
      ),
      label: Text(
        voted
            ? 'You reported this too · $count'
            : 'Me too, I have this issue${count > 0 ? ' · $count' : ''}',
      ),
    );
  }
}

class _Photos extends StatelessWidget {
  const _Photos({required this.photos});
  final List<Uint8List> photos;

  @override
  Widget build(BuildContext context) {
    Widget photo(int i, {required double height}) => GestureDetector(
      onTap: () => PhotoViewer.open(context, photos, i),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          photos[i],
          height: height,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => Container(
            height: height,
            color: AppColors.border,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );

    return Column(
      children: [
        SizedBox(width: double.infinity, child: photo(0, height: 200)),
        if (photos.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            spacing: 10,
            children: [
              for (var i = 1; i < photos.length; i++)
                Expanded(child: photo(i, height: 110)),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: c)),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
