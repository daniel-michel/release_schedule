import 'package:flutter_test/flutter_test.dart';
import 'package:release_schedule/model/date_format.dart';

void main() {
  group('dateRelativeToNow', () {
    test('returns "Today" for today\'s date', () {
      final today = DateTime.now();
      final result = dateRelativeToNow(today);
      expect(result, 'Today');
    });

    test('returns "Tomorrow" for tomorrow\'s date', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final result = dateRelativeToNow(tomorrow);
      expect(result, 'Tomorrow');
    });

    test('returns "Yesterday" for yesterday\'s date', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = dateRelativeToNow(yesterday);
      expect(result, 'Yesterday');
    });

    test('returns "In 5 days" for a date 5 days in the future', () {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final result = dateRelativeToNow(futureDate);
      expect(result, 'In 5 days');
    });

    test('returns "5 days ago" for a date 5 days in the past', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      final result = dateRelativeToNow(pastDate);
      expect(result, '5 days ago');
    });

    test('returns "a week" for a date 7 days in the future', () {
      final futureDate = DateTime.now().add(const Duration(days: 7));
      final result = dateRelativeToNow(futureDate);
      expect(result, 'In a week');
    });

    test('returns "a week" for a date 7 days in the past', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 7));
      final result = dateRelativeToNow(pastDate);
      expect(result, 'A week ago');
    });

    test('returns "a month" for a date 30 days in the future', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final result = dateRelativeToNow(futureDate);
      expect(result, 'In a month');
    });

    test('returns "a month" for a date 30 days in the past', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 30));
      final result = dateRelativeToNow(pastDate);
      expect(result, 'A month ago');
    });

    test('returns "a year" for a date 365 days in the future', () {
      final futureDate = DateTime.now().add(const Duration(days: 365));
      final result = dateRelativeToNow(futureDate);
      expect(result, 'In a year');
    });

    test('returns "a year" for a date 365 days in the past', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 365));
      final result = dateRelativeToNow(pastDate);
      expect(result, 'A year ago');
    });

    test('returns "a century" for a date 100 years in the future', () {
      final futureDate = DateTime.now().add(const Duration(days: 365 * 100));
      final result = dateRelativeToNow(futureDate);
      expect(result, 'In a century');
    });

    test('returns "a century" for a date 100 years in the past', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 365 * 100));
      final result = dateRelativeToNow(pastDate);
      expect(result, 'A century ago');
    });
  });
}
