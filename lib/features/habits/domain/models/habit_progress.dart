class HabitProgress {
  final String habitId;
  final DateTime date;
  final bool isCompleted;
  final int count;

  const HabitProgress({
    required this.habitId,
    required this.date,
    this.isCompleted = false,
    this.count = 0,
  });

  // Convert progress into a database-friendly map.
  Map<String, dynamic> toMap() {
    final dateKey =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    return {
      'habit_id': habitId,
      'date': dateKey,
      'is_completed': isCompleted ? 1 : 0,
      'count': count,
    };
  }

  // Reconstruct progress from database data.
  factory HabitProgress.fromMap(Map<String, dynamic> map) {
    return HabitProgress(
      habitId: map['habit_id'] as String,
      date: DateTime.parse(map['date'] as String),
      isCompleted: (map['is_completed'] as int) == 1,
      count: map['count'] as int,
    );
  }
}