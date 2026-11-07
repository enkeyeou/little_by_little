class CalendarDates {
  const CalendarDates._();

  static const weekdayAbbreviations = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
  ];

  static const _monthAbbreviations = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
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

  static String monthYearLabel(DateTime date) =>
      '${_monthNames[date.month - 1]} ${date.year}';

  static String weekRangeLabel(DateTime weekStart) {
    final start = dateOnly(weekStart);
    final end = start.add(const Duration(days: 6));
    if (start.year != end.year) {
      return '${_dateLabel(start, includeYear: true)} – '
          '${_dateLabel(end, includeYear: true)}';
    }

    final includeEndYear = start.month != end.month;
    return '${_dateLabel(start)} – '
        '${_dateLabel(end, includeYear: includeEndYear)}';
  }

  static String _dateLabel(DateTime date, {bool includeYear = false}) {
    final label = '${_monthAbbreviations[date.month - 1]} ${date.day}';
    return includeYear ? '$label, ${date.year}' : label;
  }
}
