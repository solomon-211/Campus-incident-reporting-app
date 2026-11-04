import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'incident.dart';

/// One entry in `incidents/{id}/updates`, shown on the status timeline.
class StatusUpdate extends Equatable {
  const StatusUpdate({
    required this.id,
    required this.status,
    required this.note,
    required this.updatedBy,
    required this.updatedByName,
    this.timestamp,
  });

  final String id;
  final IncidentStatus status;
  final String note;
  final String updatedBy;
  final String updatedByName;
  final DateTime? timestamp;

  factory StatusUpdate.fromMap(String id, Map<String, dynamic> map) {
    return StatusUpdate(
      id: id,
      status: IncidentStatus.fromName(map['status'] as String?),
      note: map['note'] as String? ?? '',
      updatedBy: map['updatedBy'] as String? ?? '',
      updatedByName: map['updatedByName'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() => {
    'status': status.name,
    'note': note,
    'updatedBy': updatedBy,
    'updatedByName': updatedByName,
    'timestamp': FieldValue.serverTimestamp(),
  };

  @override
  List<Object?> get props => [
    id,
    status,
    note,
    updatedBy,
    updatedByName,
    timestamp,
  ];
}
