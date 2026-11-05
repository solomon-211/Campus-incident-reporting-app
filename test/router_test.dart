import 'package:campus_incident_reporter/app/router.dart';
import 'package:campus_incident_reporter/features/auth/cubit/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('redirectFor', () {
    test('waits on the splash screen until auth is known', () {
      expect(redirectFor(const AuthInitial(), '/home'), '/splash');
      expect(redirectFor(const AuthInitial(), '/splash'), isNull);
    });

    test('signed-out users can only see login and register', () {
      const out = AuthUnauthenticated();
      expect(redirectFor(out, '/home'), '/login');
      expect(redirectFor(out, '/staff'), '/login');
      expect(redirectFor(out, '/login'), isNull);
      expect(redirectFor(out, '/register'), isNull);
      expect(redirectFor(const AuthError('x'), '/login'), isNull);
      expect(redirectFor(const AuthLoading(), '/register'), isNull);
    });

    test('unverified users can only see the verify-email screen', () {
      const s = AuthUnverified('a@alustudent.com');
      expect(redirectFor(s, '/home'), '/verify-email');
      expect(redirectFor(s, '/login'), '/verify-email');
      expect(redirectFor(s, '/staff'), '/verify-email');
      expect(redirectFor(s, '/verify-email'), isNull);
    });

    test('students go to Home and cannot open staff pages', () {
      const s = AuthAuthenticated(student);
      expect(redirectFor(s, '/login'), '/home');
      expect(redirectFor(s, '/splash'), '/home');
      expect(redirectFor(s, '/staff'), '/home');
      expect(redirectFor(s, '/staff/incident/1'), '/home');
      expect(redirectFor(s, '/reports'), isNull);
      expect(redirectFor(s, '/home/notifications'), isNull);
      expect(redirectFor(s, '/incident/1'), isNull);
    });

    test('staff go to the dashboard and stay in staff pages', () {
      const s = AuthAuthenticated(staff);
      expect(redirectFor(s, '/login'), '/staff');
      expect(redirectFor(s, '/home'), '/staff');
      expect(redirectFor(s, '/report'), '/staff');
      expect(redirectFor(s, '/home/notifications'), '/staff');
      expect(redirectFor(s, '/staff'), isNull);
      expect(redirectFor(s, '/staff/incident/1'), isNull);
      expect(redirectFor(s, '/staff/profile'), isNull);
    });

    test('a path that merely starts with "staff" is not a staff page', () {
      expect(
        redirectFor(const AuthAuthenticated(student), '/staffroom'),
        isNull,
      );
    });
  });
}
