import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/load_status.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/incident_repository.dart';

part 'incidents_state.dart';

/// A student's own reports, shared by the Home and My Reports screens.
class IncidentsCubit extends Cubit<IncidentsState> {
  IncidentsCubit(this._repository, {required this.reporterId})
    : super(const IncidentsState());

  final IncidentRepository _repository;
  final String reporterId;
  StreamSubscription<List<Incident>>? _sub;

  void watch() {
    _sub?.cancel();
    _sub = _repository
        .watchByReporter(reporterId)
        .listen(
          (incidents) =>
              emit(state.copyWith(status: LoadStatus.loaded, all: incidents)),
          onError: (Object e) => emit(
            state.copyWith(
              status: LoadStatus.failure,
              errorMessage: 'Could not load your reports.',
            ),
          ),
        );
  }

  /// Pull-to-refresh. The list is live already; re-subscribing recovers from
  /// an earlier error.
  Future<void> refresh() async {
    watch();
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  void search(String query) => emit(state.copyWith(query: query));

  void setStatusFilter(IncidentStatus? status) =>
      emit(state.copyWith(statusFilter: () => status));

  void setCategoryFilter(IncidentCategory? category) =>
      emit(state.copyWith(categoryFilter: () => category));

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
