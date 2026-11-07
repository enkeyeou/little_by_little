import 'package:flutter_test/flutter_test.dart';
import 'package:little_by_little/core/utils/calendar_dates.dart';

void main() {
  group('CalendarDates', () {
    test('starts weeks on Sunday', () {
      expect(
        CalendarDates.startOfWeek(DateTime(2026, 11, 7)),
        DateTime(2026, 11, 1),
      );
      expect(
        CalendarDates.startOfWeek(DateTime(2026, 11, 1)),
        DateTime(2026, 11, 1),
      );
    });

    test('aligns month days Sunday first', () {
      expect(CalendarDates.leadingDaysInMonth(DateTime(2026, 11)), 0);
      expect(CalendarDates.daysInMonth(DateTime(2026, 11)), 30);
      expect(CalendarDates.weeksInMonth(DateTime(2026, 11)), 5);
      expect(CalendarDates.leadingDaysInMonth(DateTime(2026, 8)), 6);
      expect(CalendarDates.weeksInMonth(DateTime(2026, 8)), 6);
    });

    test('formats uppercase weekdays and Sunday-first week ranges', () {
      expect(CalendarDates.weekdayAbbreviations, [
        'SUN',
        'MON',
        'TUE',
        'WED',
        'THU',
        'FRI',
        'SAT',
      ]);
      expect(
        CalendarDates.weekRangeLabel(DateTime(2026, 11, 1)),
        'Nov 1 – Nov 7',
      );
      expect(
        CalendarDates.weekRangeLabel(DateTime(2026, 12, 27)),
        'Dec 27, 2026 – Jan 2, 2027',
      );
      expect(CalendarDates.monthYearLabel(DateTime(2026, 11)), 'November 2026');
    });
  });
}
