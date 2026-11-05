import 'package:bloc_test/bloc_test.dart';
import 'package:campus_incident_reporter/app/theme.dart';
import 'package:campus_incident_reporter/data/models/app_user.dart';
import 'package:campus_incident_reporter/data/models/incident.dart';
import 'package:campus_incident_reporter/data/models/status_update.dart';
import 'package:campus_incident_reporter/data/repositories/auth_repository.dart';
import 'package:campus_incident_reporter/data/repositories/incident_repository.dart';
import 'package:campus_incident_reporter/data/services/photo_compressor.dart';
import 'package:campus_incident_reporter/features/auth/cubit/auth_cubit.dart';
import 'package:campus_incident_reporter/features/auth/screens/login_screen.dart';
import 'package:campus_incident_reporter/features/auth/screens/register_screen.dart';
import 'package:campus_incident_reporter/features/detail/cubit/incident_detail_cubit.dart';
import 'package:campus_incident_reporter/features/detail/screens/incident_detail_screen.dart';
import 'package:campus_incident_reporter/features/home/screens/home_screen.dart';
import 'package:campus_incident_reporter/features/home/screens/notifications_screen.dart';
import 'package:campus_incident_reporter/features/profile/cubit/profile_cubit.dart';
import 'package:campus_incident_reporter/features/profile/screens/profile_screen.dart';
import 'package:campus_incident_reporter/features/report/cubit/report_form_cubit.dart';
import 'package:campus_incident_reporter/features/report/screens/report_form_screen.dart';
import 'package:campus_incident_reporter/features/reports/cubit/my_reports_cubit.dart';
import 'package:campus_incident_reporter/features/reports/screens/my_reports_screen.dart';
import 'package:campus_incident_reporter/features/staff/cubit/staff_cubit.dart';
import 'package:campus_incident_reporter/features/staff/screens/staff_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockIncidentRepository extends Mock implements IncidentRepository {}

class MockPhotoCompressor extends Mock implements PhotoCompressor {}

class MockAuthRepository extends Mock implements AuthRepository {}

/// Renders screens at a typical phone size so layout overflows fail the test.
void main() {
  late MockAuthCubit auth;
  late MockIncidentRepository repo;

  final reports = [
    incident(
      id: 'a',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    incident(
      id: 'b',
      title: 'Broken classroom projector',
      location: 'Block B',
      category: IncidentCategory.electricity,
      status: IncidentStatus.inProgress,
      priority: IncidentPriority.high,
      upvoters: ['x', 'y'],
    ),
    incident(
      id: 'c',
      title: 'Overflowing bin',
      location: 'Cafeteria',
      category: IncidentCategory.sanitation,
      status: IncidentStatus.resolved,
    ),
  ];

  void loginAs(AppUser user) {
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(user),
    );
    when(() => auth.currentUser).thenReturn(user);
  }

  setUpAll(() => registerFallbackValue(incident()));

  setUp(() {
    auth = MockAuthCubit();
    repo = MockIncidentRepository();
    when(() => repo.watchByReporter(any()))
        .thenAnswer((_) => Stream.value(reports));
    when(() => repo.watchAll()).thenAnswer((_) => Stream.value(reports));
    when(() => repo.watchIncident(any()))
        .thenAnswer((_) => Stream.value(reports[1]));
    when(() => repo.watchUpdates(any())).thenAnswer(
      (_) => Stream.value([
        StatusUpdate(
          id: '1',
          status: IncidentStatus.submitted,
          note: 'Report submitted',
          updatedBy: 'student-1',
          updatedByName: 'Amina Hassan',
          timestamp: DateTime(2026, 10, 15, 10, 24),
        ),
        StatusUpdate(
          id: '2',
          status: IncidentStatus.inProgress,
          note: 'Technician assigned, visiting this afternoon.',
          updatedBy: 'staff-1',
          updatedByName: 'John Staff',
          timestamp: DateTime(2026, 10, 16, 14, 30),
        ),
      ]),
    );
  });

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: auth,
        child: MaterialApp(theme: AppTheme.light, home: screen),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('Login and Register', (tester) async {
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthUnauthenticated(),
    );
    await pump(tester, const LoginScreen());
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Email is required'), findsOneWidget);
    verifyNever(() => auth.login(any(), any()));

    await pump(tester, const RegisterScreen());
    expect(find.text('Create account'), findsWidgets);
  });

  testWidgets('Home shows greeting, summary and recent reports', (
    tester,
  ) async {
    loginAs(student);
    await pump(
      tester,
      BlocProvider(
        create: (_) => MyReportsCubit(repo, reporterId: student.uid)..watch(),
        child: const HomeScreen(),
      ),
    );
    expect(find.text('Hello, Amina!'), findsOneWidget);
    expect(find.text('Report an Issue'), findsOneWidget);
    expect(find.text('Water shortage'), findsOneWidget);
    expect(find.text('2 hours ago'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
  });

  testWidgets('Notifications list staff updates and mark them seen', (
    tester,
  ) async {
    loginAs(student);
    when(() => auth.markNotificationsSeen()).thenAnswer((_) async {});
    when(() => repo.watchByReporter(any())).thenAnswer(
      (_) => Stream.value([
        incident(
          id: 'u',
          title: 'Broken projector',
          status: IncidentStatus.inProgress,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
          lastNote: 'Technician assigned',
        ),
      ]),
    );
    await pump(
      tester,
      BlocProvider(
        create: (_) => MyReportsCubit(repo, reporterId: student.uid)..watch(),
        child: const NotificationsScreen(),
      ),
    );
    expect(find.textContaining('Broken projector'), findsOneWidget);
    expect(find.text('"Technician assigned"'), findsOneWidget);
    expect(find.text('3 hours ago'), findsOneWidget);
    verify(() => auth.markNotificationsSeen()).called(1);
  });

  testWidgets('My Reports filters by status tab', (tester) async {
    loginAs(student);
    await pump(
      tester,
      BlocProvider(
        create: (_) => MyReportsCubit(repo, reporterId: student.uid)..watch(),
        child: const MyReportsScreen(),
      ),
    );
    expect(find.text('Overflowing bin'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'In Progress'));
    await tester.pump();
    expect(find.text('Broken classroom projector'), findsOneWidget);
    expect(find.text('Overflowing bin'), findsNothing);
  });

  testWidgets('Report form validates before submitting', (tester) async {
    loginAs(student);
    await pump(
      tester,
      BlocProvider(
        create: (_) => ReportFormCubit(repo, MockPhotoCompressor()),
        child: const ReportFormScreen(),
      ),
    );
    expect(find.text('Facilities'), findsOneWidget);

    final page = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Submit Report'),
      200,
      scrollable: page,
    );
    await tester.tap(find.text('Submit Report'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Please select a category'),
      -200,
      scrollable: page,
    );
    expect(find.text('Please select a category'), findsOneWidget);
    verifyNever(() => repo.createIncident(any(), photos: any(named: 'photos')));
  });

  testWidgets('Incident details show the timeline and Me too', (tester) async {
    loginAs(const AppUser(uid: 'other', name: 'Other Student', email: 'o@x.y'));
    await pump(
      tester,
      BlocProvider(
        create: (_) => IncidentDetailCubit(repo, 'b')..watch(),
        child: const IncidentDetailScreen(),
      ),
    );
    expect(find.text('Status Timeline'), findsOneWidget);
    expect(
      find.text('Technician assigned, visiting this afternoon.'),
      findsOneWidget,
    );
    expect(find.textContaining('Me too'), findsOneWidget);
  });

  testWidgets('Staff dashboard lists every report', (tester) async {
    loginAs(staff);
    await pump(
      tester,
      BlocProvider(
        create: (_) => StaffCubit(repo)..watch(),
        child: const StaffDashboardScreen(),
      ),
    );
    expect(find.text('Staff Dashboard'), findsOneWidget);
    expect(find.text('Water shortage'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('Profile', (tester) async {
    loginAs(student);
    await pump(
      tester,
      BlocProvider(
        create: (_) => ProfileCubit(
          MockAuthRepository(),
          MockPhotoCompressor(),
          uid: student.uid,
        ),
        child: const ProfileScreen(),
      ),
    );
    expect(find.text('Amina Hassan'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });
}
