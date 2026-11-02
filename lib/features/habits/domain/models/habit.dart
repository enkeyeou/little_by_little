import 'package:flutter/material.dart';

enum TrackingType {
  completion,
  counter,
}

enum HabitScheduleType {
  everyDay,
  selectedDays,
  everyNDays,
  weeklyTarget,
}

enum CounterGoalPeriod {
  daily,
  weekly,
}

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
}