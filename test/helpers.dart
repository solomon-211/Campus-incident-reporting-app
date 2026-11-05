import 'package:campus_incident_reporter/data/models/app_user.dart';
import 'package:campus_incident_reporter/data/models/incident.dart';

const student = AppUser(
  uid: 'student-1',
  name: 'Amina Hassan',
  email: 'amina@uni.ac.rw',
  program: 'Computer Science',
);

const staff = AppUser(
  uid: 'staff-1',
  name: 'John Staff',
  email: 'john@uni.ac.rw',
  role: UserRole.staff,
);

Incident incident({
  String id = 'i1',
  String title = 'Water shortage',
  String description = 'No water supply in the residence since morning.',
  IncidentCategory category = IncidentCategory.water,
  String location = 'Student Residence',
  IncidentStatus status = IncidentStatus.submitted,
  IncidentPriority priority = IncidentPriority.medium,
  String reporterId = 'student-1',
  bool isAnonymous = false,
  List<String> upvoters = const [],
  DateTime? createdAt,
  DateTime? updatedAt,
  String? lastNote,
}) {
  return Incident(
    id: id,
    title: title,
    description: description,
    category: category,
    location: location,
    status: status,
    priority: priority,
    reporterId: reporterId,
    reporterName: 'Amina Hassan',
    isAnonymous: isAnonymous,
    upvoters: upvoters,
    createdAt: createdAt ?? DateTime(2026, 10, 20),
    updatedAt: updatedAt ?? createdAt ?? DateTime(2026, 10, 20),
    lastNote: lastNote,
  );
}
