import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum IncidentStatus {
  submitted('Submitted'),
  inProgress('In Progress'),
  resolved('Resolved'),
  rejected('Rejected');

  const IncidentStatus(this.label);
  final String label;

  static IncidentStatus fromName(String? name) =>
      IncidentStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => IncidentStatus.submitted,
      );
}

enum IncidentCategory {
  facilities('Facilities'),
  water('Water'),
  electricity('Electricity'),
  safety('Safety'),
  sanitation('Sanitation'),
  furniture('Furniture');

  const IncidentCategory(this.label);
  final String label;

  static IncidentCategory fromName(String? name) =>
      IncidentCategory.values.firstWhere(
        (c) => c.name == name,
        orElse: () => IncidentCategory.facilities,
      );
}

enum IncidentPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  const IncidentPriority(this.label);
  final String label;

  static IncidentPriority fromName(String? name) => IncidentPriority.values
      .firstWhere((p) => p.name == name, orElse: () => IncidentPriority.medium);
}

class Incident extends Equatable {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.reporterId,
    required this.reporterName,
    this.photoCount = 0,
    this.thumbnail,
    this.status = IncidentStatus.submitted,
    this.priority = IncidentPriority.medium,
    this.isAnonymous = false,
    this.upvoters = const [],
    this.createdAt,
    this.updatedAt,
    this.lastNote,
    this.hasPendingWrites = false,
  });

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String location;

  /// Number of full-size photos in the `photos` subcollection.
  final int photoCount;

  /// Small JPEG preview of the first photo, stored on the incident itself so
  /// lists don't have to load full photos.
  final Uint8List? thumbnail;
  final IncidentStatus status;
  final IncidentPriority priority;
  final String reporterId;
  final String reporterName;
  final bool isAnonymous;

  /// UIDs of students who tapped "Me too".
  final List<String> upvoters;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? lastNote;

  /// True while a local write hasn't reached the server yet (offline support).
  final bool hasPendingWrites;

  int get upvoteCount => upvoters.length;

  /// Falls back to "now" while the server timestamp is still pending.
  DateTime get createdAtOrNow => createdAt ?? DateTime.now();

  bool isUpvotedBy(String uid) => upvoters.contains(uid);

  /// True once staff have updated the status. `updatedAt` equals `createdAt`
  /// until then ("me too" votes don't change it).
  bool get hasStaffUpdate =>
      createdAt != null &&
      updatedAt != null &&
      updatedAt!.difference(createdAt!).inSeconds > 2;

  /// Anonymous reports keep [reporterId] for security rules but hide the name
  /// from everyone except the reporter.
  String reporterNameFor(String viewerUid) {
    if (!isAnonymous) return reporterName;
    return viewerUid == reporterId ? '$reporterName (anonymous)' : 'Anonymous';
  }

  /// Client-side search: Firestore has no full-text search.
  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        location.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q);
  }

  bool matches({
    String query = '',
    IncidentStatus? status,
    IncidentCategory? category,
  }) {
    if (status != null && this.status != status) return false;
    if (category != null && this.category != category) return false;
    return matchesQuery(query);
  }

  factory Incident.fromMap(
    String id,
    Map<String, dynamic> map, {
    bool hasPendingWrites = false,
  }) {
    return Incident(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: IncidentCategory.fromName(map['category'] as String?),
      location: map['location'] as String? ?? '',
      photoCount: (map['photoCount'] as num?)?.toInt() ?? 0,
      thumbnail: (map['thumbnail'] as Blob?)?.bytes,
      status: IncidentStatus.fromName(map['status'] as String?),
      priority: IncidentPriority.fromName(map['priority'] as String?),
      reporterId: map['reporterId'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? '',
      isAnonymous: map['isAnonymous'] as bool? ?? false,
      upvoters: List<String>.from(map['upvoters'] as List? ?? const []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      lastNote: map['lastNote'] as String?,
      hasPendingWrites: hasPendingWrites,
    );
  }

  Map<String, dynamic> toCreateMap() => {
    'title': title,
    'description': description,
    'category': category.name,
    'location': location,
    'photoCount': photoCount,
    'thumbnail': thumbnail == null ? null : Blob(thumbnail!),
    'status': IncidentStatus.submitted.name,
    'priority': priority.name,
    'reporterId': reporterId,
    'reporterName': reporterName,
    'isAnonymous': isAnonymous,
    'upvoters': <String>[],
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    location,
    photoCount,
    thumbnail,
    status,
    priority,
    reporterId,
    reporterName,
    isAnonymous,
    upvoters,
    createdAt,
    updatedAt,
    lastNote,
    hasPendingWrites,
  ];
}
