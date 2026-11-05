import '../../../core/incidents/incident_list_cubit.dart';
import '../../../core/load_status.dart';
import '../../../data/models/incident.dart';
import '../../../data/repositories/incident_repository.dart';

part 'my_reports_state.dart';

/// A student's own reports, shared by the Home and My Reports screens.
class MyReportsCubit extends IncidentListCubit<MyReportsState> {
  MyReportsCubit(this._repository, {required this.reporterId})
    : super(const MyReportsState());

  final IncidentRepository _repository;
  final String reporterId;

  @override
  Stream<List<Incident>> get incidents =>
      _repository.watchByReporter(reporterId);

  @override
  String get loadErrorMessage => 'Could not load your reports.';
}
