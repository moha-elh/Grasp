import 'package:flutter_test/flutter_test.dart';
import 'package:grasp/features/retention/analytics.dart';

void main() {
  // Fixed "now" so the test is stable. Local midnight is what the grid shows.
  final now = DateTime(2026, 10, 1, 9, 0);
  DateTime day(int ago) => DateTime(2026, 10, 1 - ago, 12);

  test('empty history has no streak and no first day', () {
    final s = computeStreak([], now: now);
    expect(s.streak, 0);
    expect(s.first, isNull);
    expect(s.reviewedDays, 0);
  });

  test('consecutive days up to today count as the streak', () {
    final s = computeStreak([day(0), day(1), day(2)], now: now);
    expect(s.streak, 3);
    expect(s.reviewedDays, 3);
  });

  test('today not yet reviewed does not break the streak', () {
    final s = computeStreak([day(1), day(2)], now: now);
    expect(s.streak, 2); // yesterday + the day before, today is just pending
  });

  test('a missed day ends the streak', () {
    final s = computeStreak([day(0), day(1), day(3), day(4)], now: now);
    expect(s.streak, 2); // today + yesterday; the gap at day 2 stops it
    expect(s.reviewedDays, 4);
  });

  test('two reviews on the same day count as one study day', () {
    final s = computeStreak(
        [DateTime(2026, 9, 30, 8), DateTime(2026, 9, 30, 23)], now: now);
    expect(s.reviewedDays, 1);
    expect(s.streak, 1); // yesterday, today pending
  });
}
