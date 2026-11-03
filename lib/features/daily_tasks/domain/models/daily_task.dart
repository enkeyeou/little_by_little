class DailyTask {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final bool isCompleted;
  final bool isPinned;
  final DateTime createdAt;

  const DailyTask({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    this.isCompleted = false,
    this.isPinned = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date':
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
      'is_completed': isCompleted ? 1 : 0,
      'is_pinned': isPinned ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      isCompleted: (map['is_completed'] as int) == 1,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  DailyTask copyWith({
    String? title,
    String? description,
    DateTime? date,
    bool? isCompleted,
    bool? isPinned,
  }) {
    return DailyTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
    );
  }
}
