import 'package:flutter_test/flutter_test.dart';
import 'package:trimline_parcel/utilities/time_formatter.dart';

void main() {
  group('formatTimeAgo', () {
    test('returns "Just now" for times less than 60 seconds ago', () {
      final now = DateTime.now();
      final thirtySecondsAgo = now.subtract(const Duration(seconds: 30));
      expect(formatTimeAgo(thirtySecondsAgo), equals('Just now'));
    });

    test('returns minutes for times less than 60 minutes ago', () {
      final now = DateTime.now();
      final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      
      expect(formatTimeAgo(oneMinuteAgo), equals('1 minute ago'));
      expect(formatTimeAgo(fiveMinutesAgo), equals('5 minutes ago'));
    });

    test('returns hours for times less than 24 hours ago', () {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final threeHoursAgo = now.subtract(const Duration(hours: 3));
      
      expect(formatTimeAgo(oneHourAgo), equals('1 hour ago'));
      expect(formatTimeAgo(threeHoursAgo), equals('3 hours ago'));
    });

    test('returns days for times less than 7 days ago', () {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      
      expect(formatTimeAgo(oneDayAgo), equals('1 day ago'));
      expect(formatTimeAgo(threeDaysAgo), equals('3 days ago'));
    });

    test('returns weeks for times 7 days or more ago', () {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final twoWeeksAgo = now.subtract(const Duration(days: 14));
      
      expect(formatTimeAgo(oneWeekAgo), equals('1 week ago'));
      expect(formatTimeAgo(twoWeeksAgo), equals('2 weeks ago'));
    });
  });
}
