import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/status_update.dart';

class IncidentRepository {
  IncidentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection('incidents');

  CollectionReference<Map<String, dynamic>> _updates(String incidentId) =>
      _incidents.doc(incidentId).collection('updates');

  CollectionReference<Map<String, dynamic>> _photos(String incidentId) =>
      _incidents.doc(incidentId).collection('photos');

  String newIncidentId() => _incidents.doc().id;

  /// A student's own reports, newest first. Sorted on the client so the query
  /// needs no composite index.
  Stream<List<Incident>> watchByReporter(String reporterId) {
    return _incidents
        .where('reporterId', isEqualTo: reporterId)
        .snapshots(includeMetadataChanges: true)
        .map(_toSortedList);
  }

  Stream<List<Incident>> watchAll() {
    return _incidents
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map(_toSortedList);
  }

  Stream<Incident?> watchIncident(String id) {
    return _incidents
        .doc(id)
        .snapshots(includeMetadataChanges: true)
        .map(
          (doc) => doc.exists
              ? Incident.fromMap(
                  doc.id,
                  doc.data()!,
                  hasPendingWrites: doc.metadata.hasPendingWrites,
                )
              : null,
        );
  }

  Stream<List<StatusUpdate>> watchUpdates(String incidentId) {
    return _updates(incidentId).snapshots().map((snap) {
      final updates =
          snap.docs.map((d) => StatusUpdate.fromMap(d.id, d.data())).toList()
            ..sort(
              (a, b) => (a.timestamp ?? DateTime.now()).compareTo(
                b.timestamp ?? DateTime.now(),
              ),
            );
      return updates;
    });
  }

  Future<List<Uint8List>> loadPhotos(String incidentId) async {
    final snap = await _photos(incidentId).orderBy('index').get();
    return [for (final d in snap.docs) (d.data()['data'] as Blob).bytes];
  }

  /// Writes the incident, its photos and the first timeline entry in one
  /// batch. Offline, the write lands in the local cache and syncs later, so
  /// we only wait briefly for the server.
  Future<void> createIncident(
    Incident incident, {
    List<Uint8List> photos = const [],
  }) async {
    final batch = _firestore.batch();
    batch.set(_incidents.doc(incident.id), incident.toCreateMap());
    for (var i = 0; i < photos.length; i++) {
      batch.set(_photos(incident.id).doc('$i'), {
        'index': i,
        'data': Blob(photos[i]),
      });
    }
    batch.set(
      _updates(incident.id).doc(),
      StatusUpdate(
        id: '',
        status: IncidentStatus.submitted,
        note: 'Report submitted',
        updatedBy: incident.reporterId,
        updatedByName: incident.isAnonymous
            ? 'Anonymous'
            : incident.reporterName,
      ).toCreateMap(),
    );
    await batch.commit().timeout(const Duration(seconds: 8), onTimeout: () {});
  }

  Future<void> updateStatus({
    required String incidentId,
    required IncidentStatus status,
    required IncidentPriority priority,
    required String note,
    required AppUser by,
  }) async {
    final batch = _firestore.batch();
    batch.update(_incidents.doc(incidentId), {
      'status': status.name,
      'priority': priority.name,
      'lastNote': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _updates(incidentId).doc(),
      StatusUpdate(
        id: '',
        status: status,
        note: note.trim(),
        updatedBy: by.uid,
        updatedByName: by.name,
      ).toCreateMap(),
    );
    await batch.commit().timeout(const Duration(seconds: 8), onTimeout: () {});
  }

  Future<void> setUpvote({
    required String incidentId,
    required String uid,
    required bool upvote,
  }) {
    return _incidents.doc(incidentId).update({
      'upvoters': upvote
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  /// Deletes the incident together with its photos and timeline, since
  /// Firestore doesn't remove subcollections on its own.
  Future<void> deleteIncident(String incidentId) async {
    final updates = await _updates(incidentId).get();
    final photos = await _photos(incidentId).get();
    final batch = _firestore.batch();
    for (final doc in [...updates.docs, ...photos.docs]) {
      batch.delete(doc.reference);
    }
    batch.delete(_incidents.doc(incidentId));
    await batch.commit();
  }

  List<Incident> _toSortedList(QuerySnapshot<Map<String, dynamic>> snap) {
    final list =
        snap.docs
            .map(
              (d) => Incident.fromMap(
                d.id,
                d.data(),
                hasPendingWrites: d.metadata.hasPendingWrites,
              ),
            )
            .toList()
          ..sort((a, b) => b.createdAtOrNow.compareTo(a.createdAtOrNow));
    return list;
  }
}
