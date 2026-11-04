import 'dart:typed_data';

import 'package:campus_incident_reporter/data/models/app_user.dart';
import 'package:campus_incident_reporter/data/models/incident.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('Incident', () {
    test('fromMap reads every field and tolerates missing ones', () {
      final i = Incident.fromMap('abc', {
        'title': 'Broken projector',
        'description': 'The projector in Block B will not turn on.',
        'category': 'electricity',
        'location': 'Block B',
        'photoCount': 2,
        'thumbnail': Blob(Uint8List.fromList([1, 2, 3])),
        'status': 'inProgress',
        'priority': 'high',
        'reporterId': 'u1',
        'reporterName': 'Amina',
        'upvoters': ['u2'],
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 15)),
      });
      expect(i.id, 'abc');
      expect(i.category, IncidentCategory.electricity);
      expect(i.status, IncidentStatus.inProgress);
      expect(i.priority, IncidentPriority.high);
      expect(i.upvoteCount, 1);
      expect(i.photoCount, 2);
      expect(i.thumbnail, [1, 2, 3]);
      expect(i.isAnonymous, isFalse);
      expect(i.createdAt, DateTime(2026, 10, 15));

      final empty = Incident.fromMap('x', {});
      expect(empty.status, IncidentStatus.submitted);
      expect(empty.photoCount, 0);
      expect(empty.thumbnail, isNull);
    });

    test('toCreateMap always starts as submitted with no upvotes', () {
      final map = incident(
        status: IncidentStatus.resolved,
        upvoters: ['a'],
      ).toCreateMap();
      expect(map['status'], 'submitted');
      expect(map['upvoters'], isEmpty);
    });

    test(
      'search matches title, location and description, case-insensitive',
      () {
        final i = incident();
        expect(i.matchesQuery('WATER'), isTrue);
        expect(i.matchesQuery('residence'), isTrue);
        expect(i.matchesQuery('morning'), isTrue);
        expect(i.matchesQuery('projector'), isFalse);
        expect(i.matchesQuery('  '), isTrue);
      },
    );

    test('matches combines status, category and query', () {
      final i = incident();
      expect(i.matches(status: IncidentStatus.submitted), isTrue);
      expect(i.matches(status: IncidentStatus.resolved), isFalse);
      expect(i.matches(category: IncidentCategory.safety), isFalse);
      expect(
        i.matches(
          status: IncidentStatus.submitted,
          category: IncidentCategory.water,
          query: 'water',
        ),
        isTrue,
      );
    });

    test('anonymous reports hide the name from everyone but the reporter', () {
      final i = incident(isAnonymous: true);
      expect(i.reporterNameFor('someone-else'), 'Anonymous');
      expect(i.reporterNameFor('student-1'), contains('Amina'));
      expect(incident().reporterNameFor('someone-else'), 'Amina Hassan');
    });
  });

  group('AppUser', () {
    test('defaults to student and derives names', () {
      final u = AppUser.fromMap('u', {'name': 'Amina Hassan'});
      expect(u.role, UserRole.student);
      expect(u.isStaff, isFalse);
      expect(u.firstName, 'Amina');
      expect(u.initials, 'AH');
      expect(AppUser.fromMap('s', {'role': 'staff'}).isStaff, isTrue);
    });

    test('a new profile is always written as a student', () {
      expect(student.toCreateMap()['role'], 'student');
    });
  });
}
