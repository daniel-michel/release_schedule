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

    test('returns "in X days" for future dates', () {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final result = dateRelativeToNow(futureDate);
      expect(result, 'In 5 days');
    });

    test('returns "X days ago" for past dates', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      final result = dateRelativeToNow(pastDate);
      expect(result, '5 days ago');
    });
  });
}
