class CalendarDates {
  const CalendarDates._();

  static const weekdayAbbreviations = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime startOfWeek(DateTime date) {
    final normalizedDate = dateOnly(date);
    return normalizedDate.subtract(
      Duration(days: normalizedDate.weekday % DateTime.daysPerWeek),
    );
  }

  static int leadingDaysInMonth(DateTime month) =>
      DateTime(month.year, month.month, 1).weekday % DateTime.daysPerWeek;

  static int daysInMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;

  static int weeksInMonth(DateTime month) =>
      (leadingDaysInMonth(month) + daysInMonth(month) + 6) ~/ 7;
}
