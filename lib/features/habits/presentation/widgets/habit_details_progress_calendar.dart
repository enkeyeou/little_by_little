import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/calendar_dates.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/habit_progress.dart';

class HabitDetailsProgressCalendar extends StatefulWidget {
  final Habit habit;
  final List<HabitProgress> progressHistory;
  final bool Function(DateTime date, HabitProgress? progress)
  isSuccessfulForDate;

  const HabitDetailsProgressCalendar({
    super.key,
    required this.habit,
    required this.progressHistory,
    required this.isSuccessfulForDate,
  });

  @override
  State<HabitDetailsProgressCalendar> createState() =>
      _HabitDetailsProgressCalendarState();
}

class _HabitDetailsProgressCalendarState
    extends State<HabitDetailsProgressCalendar> {
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

  HabitProgress? _getProgressForDate(DateTime date) {
    for (final progress in widget.progressHistory) {
      if (progress.habitId == widget.habit.id &&
          DateUtils.isSameDay(progress.date, date)) {
        return progress;
      }
    }

    return null;
  }

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

  @override
  Widget build(BuildContext context) {
    final weekStart = CalendarDates.startOfWeek(_focusedDate);

    return Container(
      padding: const EdgeInsets.only(top: 4),
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
      padding: const EdgeInsets.only(top: 8),
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
                SizedBox(
                  height: widget.habit.trackingType == TrackingType.counter
                      ? 56
                      : 38,
                  child: _buildDayIndicator(date),
                ),
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
    final weekCount = totalCells ~/ 7;

    final cellHeight = widget.habit.trackingType == TrackingType.counter
        ? 56.0
        : 38.0;

    final rowSpacing = widget.habit.trackingType == TrackingType.completion
        ? 12.0
        : 8.0;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
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
            children: List.generate(weekCount, (weekIndex) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: weekIndex == weekCount - 1 ? 0 : rowSpacing,
                ),
                child: Row(
                  children: List.generate(7, (dayIndex) {
                    final index = weekIndex * 7 + dayIndex;
                    final day = index - leadingDays + 1;

                    if (day < 1 || day > daysInMonth) {
                      return Expanded(child: SizedBox(height: cellHeight));
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
    final habit = widget.habit;
    final progress = _getProgressForDate(date);

    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isSuccessful = widget.isSuccessfulForDate(date, progress);

    final count = progress?.count ?? 0;

    final hasDailyCounterGoal =
        habit.trackingType == TrackingType.counter &&
        habit.counterGoalPeriod == CounterGoalPeriod.daily &&
        habit.counterGoal != null &&
        habit.counterGoal! > 0;

    final showProgressRing =
        habit.trackingType == TrackingType.counter && hasDailyCounterGoal;

    final showCounterOutline =
        habit.trackingType == TrackingType.counter &&
        !hasDailyCounterGoal &&
        count > 0;

    final ringProgress = showProgressRing
        ? (count / habit.counterGoal!).clamp(0.0, 1.0)
        : 0.0;

    return SizedBox(
      width: 38,
      height: habit.trackingType == TrackingType.counter ? 56 : 38,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (showProgressRing)
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      value: ringProgress,
                      strokeWidth: 3,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.surfaceElevated,
                      color: AppColors.primary,
                    ),
                  )
                else if (habit.trackingType == TrackingType.completion)
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      value: isSuccessful ? 1.0 : 0.0,
                      strokeWidth: 3,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.border,
                      color: AppColors.primary,
                    ),
                  )
                else if (showCounterOutline)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                    ),
                  ),
                if (isToday)
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${date.day}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  Center(
                    child: Text(
                      '${date.day}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (habit.trackingType == TrackingType.counter)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: SizedBox(
                height: 14,
                child: Text(
                  count > 0 ? '$count' : '',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
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
