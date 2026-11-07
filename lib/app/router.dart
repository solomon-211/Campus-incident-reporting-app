import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/incidents/incident_alerts.dart';
import '../data/models/incident.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/incident_repository.dart';
import '../data/services/photo_compressor.dart';
import '../features/auth/cubit/auth_cubit.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/verify_email_screen.dart';
import '../features/detail/cubit/incident_detail_cubit.dart';
import '../features/detail/screens/incident_detail_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/notifications_screen.dart';
import '../features/profile/cubit/profile_cubit.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/report/cubit/report_form_cubit.dart';
import '../features/report/screens/report_form_screen.dart';
import '../features/reports/cubit/my_reports_cubit.dart';
import '../features/reports/screens/my_reports_screen.dart';
import '../features/staff/cubit/staff_cubit.dart';
import '../features/staff/screens/staff_dashboard_screen.dart';
import '../features/staff/widgets/update_status_sheet.dart';
import 'student_shell.dart';

/// Routes:
///   /splash, /login, /register         signed out
///   /verify-email                      signed in, email not verified
///   /home, /reports, /profile          student tabs (bottom nav)
///   /home/notifications                status updates on my reports
///   /report, /incident/:id             student, pushed over the tabs
///   /staff, /staff/incident/:id, /staff/profile   staff only
GoRouter createRouter(AuthCubit authCubit) {
  final rootKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/splash',
    refreshListenable: _StreamListenable(authCubit.stream),
    redirect: (context, state) =>
        redirectFor(authCubit.state, state.matchedLocation),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (_, _) => const VerifyEmailScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => BlocProvider(
          // Shared by Home and My Reports, closed on logout when the shell
          // leaves the tree.
          create: (context) => MyReportsCubit(
            context.read<IncidentRepository>(),
            reporterId: authCubit.currentUser!.uid,
          )..watch(),
          child: IncidentAlertListener<MyReportsCubit, MyReportsState>(
            alertsFor: (previous, current) => [
              for (final i in statusChanges(previous, current))
                '"${i.title}" is now ${i.status.label}',
            ],
            child: StudentShell(navigationShell: navigationShell),
          ),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    builder: (_, _) => const NotificationsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (_, _) => const MyReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => _profilePage(authCubit),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/report',
        parentNavigatorKey: rootKey,
        // Optional ?category=water preselects a category (home shortcuts).
        builder: (context, state) => BlocProvider(
          create: (context) => ReportFormCubit(
            context.read<IncidentRepository>(),
            context.read<PhotoCompressor>(),
            initialCategory: IncidentCategory.values
                .asNameMap()[state.uri.queryParameters['category']],
          ),
          child: const ReportFormScreen(),
        ),
      ),
      GoRoute(
        path: '/incident/:id',
        parentNavigatorKey: rootKey,
        builder: (context, state) => BlocProvider(
          create: (context) => IncidentDetailCubit(
            context.read<IncidentRepository>(),
            state.pathParameters['id']!,
          )..watch(),
          child: const IncidentDetailScreen(),
        ),
      ),

      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (context) =>
              StaffCubit(context.read<IncidentRepository>())..watch(),
          child: IncidentAlertListener<StaffCubit, StaffState>(
            alertsFor: (previous, current) => [
              for (final i in newIncidents(previous, current))
                'New report: ${i.title}',
            ],
            child: child,
          ),
        ),
        routes: [
          GoRoute(
            path: '/staff',
            builder: (_, _) => const StaffDashboardScreen(),
            routes: [
              GoRoute(
                path: 'incident/:id',
                builder: (context, state) => BlocProvider(
                  create: (context) => IncidentDetailCubit(
                    context.read<IncidentRepository>(),
                    state.pathParameters['id']!,
                  )..watch(),
                  child: BlocBuilder<IncidentDetailCubit, IncidentDetailState>(
                    buildWhen: (a, b) => a.incident != b.incident,
                    builder: (context, detail) => IncidentDetailScreen(
                      bottomAction: UpdateStatusButton(
                        incident: detail.incident,
                      ),
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: 'profile',
                builder: (_, _) => _profilePage(authCubit),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Profile for either role, with its own cubit for changing the photo.
Widget _profilePage(AuthCubit authCubit) => Builder(
  builder: (context) => BlocProvider(
    create: (context) => ProfileCubit(
      context.read<AuthRepository>(),
      context.read<PhotoCompressor>(),
      uid: authCubit.currentUser!.uid,
    ),
    child: const ProfileScreen(),
  ),
);

/// Sends each user to the right place for their auth state and role. The
/// security rules enforce the same split on the server.
String? redirectFor(AuthState auth, String location) {
  final atAuthPage = location == '/login' || location == '/register';

  if (auth is AuthInitial) return location == '/splash' ? null : '/splash';

  if (auth is AuthUnverified) {
    return location == '/verify-email' ? null : '/verify-email';
  }

  if (auth is! AuthAuthenticated) return atAuthPage ? null : '/login';

  final isStaff = auth.user.isStaff;
  final home = isStaff ? '/staff' : '/home';
  final atStaffPage = location == '/staff' || location.startsWith('/staff/');

  // Signed in: the entry screens (including verify-email, just after a
  // student verifies) are no longer needed, so go home.
  if (location == '/splash' || location == '/verify-email' || atAuthPage) {
    return home;
  }
  if (isStaff && !atStaffPage) return home;
  if (!isStaff && atStaffPage) return home;
  return null;
}

/// Lets go_router re-run its redirect whenever the auth state changes.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
