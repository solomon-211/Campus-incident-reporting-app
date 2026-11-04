import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/incident.dart';
import '../../../data/models/status_update.dart';
import '../../../data/repositories/incident_repository.dart';

part 'incident_detail_state.dart';

class IncidentDetailCubit extends Cubit<IncidentDetailState> {
  IncidentDetailCubit(this._repository, this.incidentId)
    : super(const IncidentDetailState());

  final IncidentRepository _repository;
  final String incidentId;
  StreamSubscription<Incident?>? _incidentSub;
  StreamSubscription<List<StatusUpdate>>? _timelineSub;
  bool _photosRequested = false;

  void watch() {
    _incidentSub?.cancel();
    _timelineSub?.cancel();

    _incidentSub = _repository.watchIncident(incidentId).listen(
      (incident) {
        if (incident == null) {
          // A report saved offline may not be in the cache yet; only give up
          // once we've shown nothing so far.
          if (state.incident == null) {
            emit(state.copyWith(status: DetailStatus.notFound));
          }
          return;
        }
        emit(state.copyWith(status: DetailStatus.loaded, incident: incident));
        if (incident.photoCount > 0 && !_photosRequested) _loadPhotos();
      },
      onError: (Object e) => emit(
        state.copyWith(
          status: DetailStatus.failure,
          errorMessage: 'Could not load this report.',
        ),
      ),
    );

    _timelineSub = _repository
        .watchUpdates(incidentId)
        .listen(
          (timeline) => emit(state.copyWith(timeline: timeline)),
          // The timeline is secondary; keep showing the incident on error.
          onError: (Object _) {},
        );
  }

  Future<void> _loadPhotos() async {
    _photosRequested = true;
    emit(state.copyWith(photosLoading: true));
    try {
      final photos = await _repository.loadPhotos(incidentId);
      if (!isClosed) {
        emit(state.copyWith(photos: photos, photosLoading: false));
      }
    } catch (_) {
      // Allow a retry the next time the incident updates.
      _photosRequested = false;
      if (!isClosed) emit(state.copyWith(photosLoading: false));
    }
  }

  /// "Me too". Returns an error message, or null on success.
  Future<String?> toggleUpvote(String uid) async {
    final incident = state.incident;
    if (incident == null) return null;
    try {
      await _repository.setUpvote(
        incidentId: incident.id,
        uid: uid,
        upvote: !incident.isUpvotedBy(uid),
      );
      return null;
    } catch (_) {
      return 'Could not update. Please try again.';
    }
  }

  @override
  Future<void> close() async {
    await _incidentSub?.cancel();
    await _timelineSub?.cancel();
    return super.close();
  }
}
