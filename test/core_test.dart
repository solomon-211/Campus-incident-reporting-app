import 'package:campus_incident_reporter/core/extensions.dart';
import 'package:campus_incident_reporter/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('a.hassan@alustudent.com'), isNull);
      expect(Validators.email('j.doe@alueducation.com'), isNull);
      expect(Validators.email('A.Hassan@ALUSTUDENT.COM'), isNull);
    });

    test('only ALU email addresses are accepted', () {
      expect(Validators.email('amina@gmail.com'), contains('ALU'));
      expect(Validators.email('amina@alustudent.com.fake.io'), isNotNull);
    });

    test('password needs 6+ characters', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('title is 5 to 80 characters', () {
      expect(Validators.title('Leak'), isNotNull);
      expect(Validators.title('Water leak'), isNull);
      expect(Validators.title('x' * 80), isNull);
      expect(Validators.title('x' * 81), isNotNull);
      expect(Validators.title('   Leak   '), isNotNull, reason: 'trimmed');
    });

    test('description needs 15+ characters', () {
      expect(Validators.description('Too short'), isNotNull);
      expect(
        Validators.description('The tap has been running all day'),
        isNull,
      );
    });

    test('at most 3 attachments', () {
      expect(Validators.attachmentCount(3), isNull);
      expect(Validators.attachmentCount(4), isNotNull);
    });
  });

  group('timeAgo', () {
    final now = DateTime(2026, 10, 22, 12);

    test('formats relative times', () {
      expect(now.timeAgo(now), 'Just now');
      expect(
        now.subtract(const Duration(minutes: 5)).timeAgo(now),
        '5 min ago',
      );
      expect(now.subtract(const Duration(hours: 1)).timeAgo(now), '1 hour ago');
      expect(
        now.subtract(const Duration(hours: 2)).timeAgo(now),
        '2 hours ago',
      );
      expect(now.subtract(const Duration(days: 1)).timeAgo(now), '1 day ago');
      expect(now.subtract(const Duration(days: 3)).timeAgo(now), '3 days ago');
    });

    test('falls back to a date after a week', () {
      expect(DateTime(2026, 10, 1).timeAgo(now), 'Oct 1, 2026');
    });
  });
}
