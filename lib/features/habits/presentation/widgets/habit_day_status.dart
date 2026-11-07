enum HabitDayStatus { completed, missed, upcoming, notScheduled, today }

extension HabitDayStatusLabel on HabitDayStatus {
  String get label => switch (this) {
    HabitDayStatus.completed => 'Completed',
    HabitDayStatus.missed => 'Missed',
    HabitDayStatus.upcoming => 'Upcoming',
    HabitDayStatus.notScheduled => 'Not scheduled',
    HabitDayStatus.today => 'Today',
  };
}
