import '../../../core/incidents/incident_list_cubit.dart';
import '../../../core/load_status.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/incident_repository.dart';

part 'staff_state.dart';

class StaffCubit extends IncidentListCubit<StaffState> {
  StaffCubit(this._repository) : super(const StaffState());

  final IncidentRepository _repository;

  @override
  Stream<List<Incident>> get incidents => _repository.watchAll();

  @override
  String get loadErrorMessage =>
      'Could not load reports. Is this account staff?';

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
}
