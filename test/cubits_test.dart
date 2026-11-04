import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:campus_incident_reporter/core/load_status.dart';
import 'package:campus_incident_reporter/data/models/incident.dart';
import 'package:campus_incident_reporter/data/repositories/incident_repository.dart';
import 'package:campus_incident_reporter/data/repositories/photo_repository.dart';
import 'package:campus_incident_reporter/features/report/cubit/report_form_cubit.dart';
import 'package:campus_incident_reporter/features/reports/cubit/incidents_cubit.dart';
import 'package:campus_incident_reporter/features/staff/cubit/staff_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers.dart';

class MockIncidentRepository extends Mock implements IncidentRepository {}

class MockPhotoRepository extends Mock implements PhotoRepository {}

void main() {
  late MockIncidentRepository incidents;
  late MockPhotoRepository photos;

  setUpAll(() {
    registerFallbackValue(incident());
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(<Uint8List>[]);
    registerFallbackValue(student);
    registerFallbackValue(IncidentStatus.submitted);
    registerFallbackValue(IncidentPriority.medium);
  });

  setUp(() {
    incidents = MockIncidentRepository();
    photos = MockPhotoRepository();
  });

  final water = incident(id: 'a', status: IncidentStatus.submitted);
  final projector = incident(
    id: 'b',
    title: 'Broken classroom projector',
    location: 'Block B',
    description: 'The projector does not turn on at all.',
    category: IncidentCategory.electricity,
    status: IncidentStatus.inProgress,
    priority: IncidentPriority.high,
    upvoters: ['x', 'y'],
  );
  final bin = incident(
    id: 'c',
    title: 'Overflowing bin',
    location: 'Cafeteria',
    description: 'The bin near the entrance is overflowing.',
    category: IncidentCategory.sanitation,
    status: IncidentStatus.resolved,
    priority: IncidentPriority.low,
    upvoters: ['x'],
  );

  group('IncidentsCubit', () {
    blocTest<IncidentsCubit, IncidentsState>(
      'loads the reporter\'s incidents and filters them on the client',
      setUp: () =>
          when(() => incidents.watchByReporter('student-1'))
              .thenAnswer((_) => Stream.value([water, projector, bin])),
      build: () => IncidentsCubit(incidents, reporterId: 'student-1'),
      act: (cubit) async {
        cubit.watch();
        await Future<void>.delayed(Duration.zero);
        cubit.setStatusFilter(IncidentStatus.inProgress);
      },
      verify: (cubit) {
        expect(cubit.state.status, LoadStatus.loaded);
        expect(cubit.state.all, hasLength(3));
        expect(cubit.state.filtered.map((i) => i.id), ['b']);
        expect(cubit.state.count(IncidentStatus.resolved), 1);
      },
    );

    blocTest<IncidentsCubit, IncidentsState>(
      'search and category filters combine, and can be cleared',
      seed: () => IncidentsState(
        status: LoadStatus.loaded,
        all: [water, projector, bin],
      ),
      build: () => IncidentsCubit(incidents, reporterId: 'student-1'),
      act: (cubit) {
        cubit.search('cafeteria');
        expect(cubit.state.filtered.map((i) => i.id), ['c']);
        cubit.setCategoryFilter(IncidentCategory.water);
        expect(cubit.state.filtered, isEmpty);
        cubit
          ..search('')
          ..setCategoryFilter(null);
      },
      verify: (cubit) => expect(cubit.state.filtered, hasLength(3)),
    );

    blocTest<IncidentsCubit, IncidentsState>(
      'emits failure when the stream errors',
      setUp: () =>
          when(() => incidents.watchByReporter(any()))
              .thenAnswer((_) => Stream.error(Exception('permission-denied'))),
      build: () => IncidentsCubit(incidents, reporterId: 'student-1'),
      act: (cubit) => cubit.watch(),
      verify: (cubit) => expect(cubit.state.status, LoadStatus.failure),
    );
  });

  group('Notifications', () {
    final created = DateTime(2026, 10, 20, 9);
    final untouched = incident(id: 'n1', createdAt: created);
    final olderUpdate = incident(
      id: 'n2',
      createdAt: created,
      updatedAt: DateTime(2026, 10, 21),
      status: IncidentStatus.inProgress,
      lastNote: 'Plumber assigned',
    );
    final newerUpdate = incident(
      id: 'n3',
      createdAt: created,
      updatedAt: DateTime(2026, 10, 22),
      status: IncidentStatus.resolved,
    );
    final state = IncidentsState(
      status: LoadStatus.loaded,
      all: [untouched, olderUpdate, newerUpdate],
    );

    test('only include reports staff have updated, newest first', () {
      expect(untouched.hasStaffUpdate, isFalse);
      expect(state.notifications.map((i) => i.id), ['n3', 'n2']);
    });

    test('count updates newer than the last time they were seen', () {
      expect(state.unreadCount(null), 2);
      expect(state.unreadCount(DateTime(2026, 10, 21, 12)), 1);
      expect(state.unreadCount(DateTime(2026, 10, 23)), 0);
    });
  });

  group('StaffCubit', () {
    blocTest<StaffCubit, StaffState>(
      'sorts by "me too" count and by priority',
      seed: () =>
          StaffState(status: LoadStatus.loaded, all: [water, projector, bin]),
      build: () => StaffCubit(incidents),
      act: (cubit) {
        cubit.setSort(StaffSort.mostUpvoted);
        expect(cubit.state.filtered.map((i) => i.id), ['b', 'c', 'a']);
        cubit.setSort(StaffSort.priority);
      },
      verify: (cubit) =>
          expect(cubit.state.filtered.map((i) => i.id), ['b', 'a', 'c']),
    );

    test('counts per status include an "All" total', () {
      final state = StaffState(
        status: LoadStatus.loaded,
        all: [water, projector, bin],
      );
      expect(state.counts[null], 3);
      expect(state.counts[IncidentStatus.rejected], 0);
    });

    test('updateStatus requires a note and calls the repository', () async {
      when(
        () => incidents.updateStatus(
          incidentId: any(named: 'incidentId'),
          status: any(named: 'status'),
          priority: any(named: 'priority'),
          note: any(named: 'note'),
          by: any(named: 'by'),
        ),
      ).thenAnswer((_) async {});
      final cubit = StaffCubit(incidents);

      final missingNote = await cubit.updateStatus(
        incidentId: 'a',
        status: IncidentStatus.inProgress,
        priority: IncidentPriority.high,
        note: '  ',
        by: staff,
      );
      expect(missingNote, isNotNull);

      final ok = await cubit.updateStatus(
        incidentId: 'a',
        status: IncidentStatus.inProgress,
        priority: IncidentPriority.high,
        note: 'Plumber assigned',
        by: staff,
      );
      expect(ok, isNull);
      verify(
        () => incidents.updateStatus(
          incidentId: 'a',
          status: IncidentStatus.inProgress,
          priority: IncidentPriority.high,
          note: 'Plumber assigned',
          by: staff,
        ),
      ).called(1);
      await cubit.close();
    });
  });

  group('ReportFormCubit', () {
    void fillValidForm(ReportFormCubit cubit) {
      cubit
        ..setCategory(IncidentCategory.water)
        ..setTitle('Water shortage')
        ..setDescription('No water in the residence since this morning.')
        ..setLocation('Student Residence');
    }

    test('shows errors and does not submit an invalid form', () async {
      final cubit = ReportFormCubit(incidents, photos);
      await cubit.submit(student);
      expect(cubit.state.showErrors, isTrue);
      expect(cubit.state.categoryError, isNotNull);
      expect(cubit.state.titleError, isNotNull);
      expect(cubit.state.status, ReportFormStatus.editing);
      verifyNever(
        () => incidents.createIncident(any(), photos: any(named: 'photos')),
      );
      await cubit.close();
    });

    test('can start with a category chosen (home shortcuts)', () async {
      final cubit = ReportFormCubit(
        incidents,
        photos,
        initialCategory: IncidentCategory.water,
      );
      expect(cubit.state.category, IncidentCategory.water);
      expect(cubit.state.categoryError, isNull);
      await cubit.close();
    });

    test('caps photos at 3', () async {
      final cubit = ReportFormCubit(incidents, photos);
      final dropped = cubit.addImages(List.generate(5, (_) => Uint8List(1)));
      expect(dropped, 2);
      expect(cubit.state.images, hasLength(3));
      expect(cubit.state.canAddPhotos, isFalse);
      cubit.removeImage(0);
      expect(cubit.state.images, hasLength(2));
      await cubit.close();
    });

    test(
      'compresses photos, then saves them with the incident as the reporter',
      () async {
        final full = Uint8List(10);
        final thumb = Uint8List(2);
        when(() => incidents.newIncidentId()).thenReturn('new-id');
        when(() => photos.prepare(any())).thenAnswer(
          (_) async => PreparedPhotos(photos: [full], thumbnail: thumb),
        );
        when(
          () => incidents.createIncident(any(), photos: any(named: 'photos')),
        ).thenAnswer((_) async {});

        final cubit = ReportFormCubit(incidents, photos);
        fillValidForm(cubit);
        cubit
          ..setAnonymous(true)
          ..addImages([Uint8List(3)]);
        await cubit.submit(student);

        expect(cubit.state.status, ReportFormStatus.success);
        expect(cubit.state.createdIncidentId, 'new-id');
        final captured = verify(
          () => incidents.createIncident(
            captureAny(),
            photos: captureAny(named: 'photos'),
          ),
        ).captured;
        final created = captured[0] as Incident;
        expect(created.id, 'new-id');
        expect(created.reporterId, student.uid);
        expect(created.photoCount, 1);
        expect(created.thumbnail, same(thumb));
        expect(created.isAnonymous, isTrue);
        expect(created.status, IncidentStatus.submitted);
        expect(captured[1], [full]);
        await cubit.close();
      },
    );

    test('saves a report without photos', () async {
      when(() => incidents.newIncidentId()).thenReturn('new-id');
      when(() => photos.prepare(any())).thenAnswer(
        (_) async => const PreparedPhotos(photos: [], thumbnail: null),
      );
      when(() => incidents.createIncident(any(), photos: any(named: 'photos')))
          .thenAnswer((_) async {});

      final cubit = ReportFormCubit(incidents, photos);
      fillValidForm(cubit);
      await cubit.submit(student);

      expect(cubit.state.status, ReportFormStatus.success);
      final created =
          verify(
                () => incidents.createIncident(
                  captureAny(),
                  photos: any(named: 'photos'),
                ),
              ).captured.single
              as Incident;
      expect(created.photoCount, 0);
      expect(created.thumbnail, isNull);
      await cubit.close();
    });

    test('shows a clear message when a photo is too large', () async {
      when(() => incidents.newIncidentId()).thenReturn('new-id');
      when(() => photos.prepare(any()))
          .thenThrow(const PhotoTooLargeException());

      final cubit = ReportFormCubit(incidents, photos);
      fillValidForm(cubit);
      cubit.addImages([Uint8List(3)]);
      await cubit.submit(student);

      expect(cubit.state.status, ReportFormStatus.failure);
      expect(cubit.state.errorMessage, contains('too large'));
      verifyNever(
        () => incidents.createIncident(any(), photos: any(named: 'photos')),
      );
      await cubit.close();
    });

    test('reports failure when saving fails', () async {
      when(() => incidents.newIncidentId()).thenReturn('new-id');
      when(() => photos.prepare(any())).thenAnswer(
        (_) async => const PreparedPhotos(photos: [], thumbnail: null),
      );
      when(() => incidents.createIncident(any(), photos: any(named: 'photos')))
          .thenThrow(Exception('permission-denied'));

      final cubit = ReportFormCubit(incidents, photos);
      fillValidForm(cubit);
      await cubit.submit(student);

      expect(cubit.state.status, ReportFormStatus.failure);
      expect(cubit.state.errorMessage, contains('connection'));
      await cubit.close();
    });
  });
}
