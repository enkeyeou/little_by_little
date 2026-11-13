import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/calendar_dates.dart';
import '../../../habits/domain/models/habit.dart';
import '../../../habits/domain/models/habit_progress.dart';

class HabitProgressCalendar extends StatefulWidget {
  final List<Habit> habits;
  final List<HabitProgress> progressHistory;

  const HabitProgressCalendar({
    super.key,
    required this.habits,
    required this.progressHistory,
  });

  @override
  State<HabitProgressCalendar> createState() => _HabitProgressCalendarState();
}

class _HabitProgressCalendarState extends State<HabitProgressCalendar> {
  bool _isExpanded = false;

  late DateTime _focusedDate;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();

    _focusedDate = _dateOnly(DateTime.now());
    _visibleMonth = DateTime(_focusedDate.year, _focusedDate.month);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  void _toggleCalendar() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _changePeriod(int direction) {
    setState(() {
      if (_isExpanded) {
        _visibleMonth = DateTime(
          _visibleMonth.year,
          _visibleMonth.month + direction,
        );
      } else {
        _focusedDate = _focusedDate.add(Duration(days: direction * 7));

        _visibleMonth = DateTime(_focusedDate.year, _focusedDate.month);
      }
    });
  }

  double _getDailyProgress(DateTime date) {
    final scheduledHabits = widget.habits.where((habit) {
      return !_dateOnly(date).isBefore(_dateOnly(habit.createdAt)) &&
          habit.isScheduledFor(date);
    }).toList();

    if (scheduledHabits.isEmpty) return 0;

    final completedCount = scheduledHabits.where((habit) {
      final progress = _getHabitProgress(habit.id, date);

      if (progress == null) return false;

      if (habit.trackingType == TrackingType.completion) {
        return progress.isCompleted;
      }

      if (habit.counterGoalPeriod == CounterGoalPeriod.weekly) {
        return progress.count > 0;
      }

      final goal = habit.counterGoal;

      return goal == null ? progress.count > 0 : progress.count >= goal;
    }).length;

    return completedCount / scheduledHabits.length;
  }

  HabitProgress? _getHabitProgress(String habitId, DateTime date) {
    for (final progress in widget.progressHistory) {
      if (progress.habitId == habitId &&
          DateUtils.isSameDay(progress.date, date)) {
        return progress;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = CalendarDates.startOfWeek(_focusedDate);

    return Container(
      padding: const EdgeInsets.only(top: 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: _toggleCalendar,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        _monthLabel(_visibleMonth),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _changePeriod(-1),
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _changePeriod(1),
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _isExpanded ? _buildMonthView() : _buildWeekView(weekStart),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(DateTime weekStart) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));

          return Expanded(
            child: Column(
              children: [
                Text(
                  CalendarDates.weekdayAbbreviations[index].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDayIndicator(date),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMonthView() {
    final daysInMonth = CalendarDates.daysInMonth(_visibleMonth);
    final leadingDays = CalendarDates.leadingDaysInMonth(_visibleMonth);
    final totalCells = CalendarDates.weeksInMonth(_visibleMonth) * 7;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          Row(
            children: CalendarDates.weekdayAbbreviations.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(totalCells ~/ 7, (weekIndex) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: weekIndex == (totalCells ~/ 7) - 1 ? 0 : 10,
                ),
                child: Row(
                  children: List.generate(7, (dayIndex) {
                    final index = weekIndex * 7 + dayIndex;
                    final day = index - leadingDays + 1;

                    if (day < 1 || day > daysInMonth) {
                      return const Expanded(child: SizedBox(height: 38));
                    }

                    final date = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month,
                      day,
                    );

                    return Expanded(
                      child: Center(child: _buildDayIndicator(date)),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayIndicator(DateTime date) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    final progress = _getDailyProgress(date);

    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.surfaceElevated,
              color: AppColors.primary,
            ),
          ),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday ? AppColors.surfaceElevated : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: isToday ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime month) {
    const months = [
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

    return '${months[month.month - 1]} ${month.year}';
  }
}
