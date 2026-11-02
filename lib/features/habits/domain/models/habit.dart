import 'package:flutter/material.dart';
import 'dart:convert';

enum TrackingType { completion, counter }

enum HabitScheduleType { everyDay, selectedDays, everyNDays, weeklyTarget }

enum CounterGoalPeriod { daily, weekly }

class Habit {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final Color color;

  final TrackingType trackingType;

  final int? counterGoal;
  final String counterUnit;
  final CounterGoalPeriod counterGoalPeriod;

  final HabitScheduleType scheduleType;
  final Set<int> selectedWeekdays;
  final int everyNDays;
  final int weeklyTarget;

  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.name,
    this.description = '',
    required this.emoji,
    required this.color,
    required this.trackingType,
    this.counterGoal,
    this.counterUnit = 'times',
    this.counterGoalPeriod = CounterGoalPeriod.daily,
    required this.scheduleType,
    this.selectedWeekdays = const {},
    this.everyNDays = 2,
    this.weeklyTarget = 3,
    required this.createdAt,
  });

  bool isScheduledFor(DateTime date) {
    switch (scheduleType) {
      case HabitScheduleType.everyDay:
        return true;

      case HabitScheduleType.selectedDays:
        return selectedWeekdays.contains(date.weekday);

      case HabitScheduleType.everyNDays:
        if (everyNDays <= 0) return false;

        final startDate = DateTime(
          createdAt.year,
          createdAt.month,
          createdAt.day,
        );

        final targetDate = DateTime(date.year, date.month, date.day);

        final difference = targetDate.difference(startDate).inDays;

        return difference >= 0 && difference % everyNDays == 0;

      case HabitScheduleType.weeklyTarget:
        return true;
    }
  }

  // Convert Habit into a database-friendly map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'emoji': emoji,
      'color_value': color.toARGB32(),
      'tracking_type': trackingType.name,
      'counter_goal': counterGoal,
      'counter_unit': counterUnit,
      'counter_goal_period': counterGoalPeriod.name,
      'schedule_type': scheduleType.name,
      'selected_weekdays': jsonEncode(selectedWeekdays.toList()),
      'every_n_days': everyNDays,
      'weekly_target': weeklyTarget,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Reconstruct Habit from database data.
  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      emoji: map['emoji'] as String,
      color: Color(map['color_value'] as int),
      trackingType: TrackingType.values.byName(map['tracking_type'] as String),
      counterGoal: map['counter_goal'] as int?,
      counterUnit: map['counter_unit'] as String,
      counterGoalPeriod: CounterGoalPeriod.values.byName(
        map['counter_goal_period'] as String,
      ),
      scheduleType: HabitScheduleType.values.byName(
        map['schedule_type'] as String,
      ),
      selectedWeekdays: Set<int>.from(
        (jsonDecode(map['selected_weekdays'] as String) as List).map(
          (day) => day as int,
        ),
      ),
      everyNDays: map['every_n_days'] as int,
      weeklyTarget: map['weekly_target'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
