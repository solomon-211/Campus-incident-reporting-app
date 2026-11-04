import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/load_status.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/incident_repository.dart';

part 'staff_state.dart';

class StaffCubit extends Cubit<StaffState> {
  StaffCubit(this._repository) : super(const StaffState());

  final IncidentRepository _repository;
  StreamSubscription<List<Incident>>? _sub;

  void watch() {
    _sub?.cancel();
    _sub = _repository.watchAll().listen(
      (incidents) =>
          emit(state.copyWith(status: LoadStatus.loaded, all: incidents)),
      onError: (Object e) => emit(
        state.copyWith(
          status: LoadStatus.failure,
          errorMessage: 'Could not load reports. Is this account staff?',
        ),
      ),
    );
  }

  Future<void> refresh() async {
    watch();
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  void search(String query) => emit(state.copyWith(query: query));

  void setStatusFilter(IncidentStatus? status) =>
      emit(state.copyWith(statusFilter: () => status));

  void setCategoryFilter(IncidentCategory? category) =>
      emit(state.copyWith(categoryFilter: () => category));

  void setSort(StaffSort sort) => emit(state.copyWith(sort: sort));

  /// Updates the status and adds a timeline entry in one batch write.
  /// Returns an error message, or null on success.
  Future<String?> updateStatus({
    required String incidentId,
    required IncidentStatus status,
    required IncidentPriority priority,
    required String note,
    required AppUser by,
  }) async {
    if (note.trim().isEmpty) return 'Please add a note for the reporter.';
    try {
      await _repository.updateStatus(
        incidentId: incidentId,
        status: status,
        priority: priority,
        note: note,
        by: by,
      );
      return null;
    } catch (_) {
      return 'Could not update the status. Please try again.';
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
