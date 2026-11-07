import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/habit.dart';
import 'add_habit_screen.dart';
import '../../data/datasources/habit_progress_local_data_source.dart';
import '../../domain/models/habit_progress.dart';

class HabitDetailsScreen extends StatefulWidget {
  final Habit habit;
  final Future<bool> Function(String id)? onHabitDeleted;

  const HabitDetailsScreen({
    super.key,
    required this.habit,
    this.onHabitDeleted,
  });

  @override
  State<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
}

class _HabitDetailsScreenState extends State<HabitDetailsScreen> {
  final HabitProgressLocalDataSource _progressDataSource =
      HabitProgressLocalDataSource();

  List<HabitProgress> _progressHistory = [];
  bool _isLoadingProgress = true;
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _visibleMonth = DateTime(today.year, today.month);
    _selectedDate = today;
    _loadProgressHistory();
  }

  Future<void> _loadProgressHistory() async {
    final history = await _progressDataSource.getProgressForHabit(
      widget.habit.id,
    );

    if (!mounted) return;

    setState(() {
      _progressHistory = history;
      _isLoadingProgress = false;
    });
  }

  int _getTotalCompletions() {
    if (widget.habit.trackingType == TrackingType.completion) {
      return _progressHistory.where((progress) => progress.isCompleted).length;
    }

    return _progressHistory.fold(
      0,
      (total, progress) => total + progress.count,
    );
  }

  int _getHighestDailyCount() {
    if (_progressHistory.isEmpty) return 0;

    return _progressHistory.fold(
      0,
      (highest, progress) =>
          progress.count > highest ? progress.count : highest,
    );
  }

  bool _usesWeeklyStreak() {
    return widget.habit.scheduleType == HabitScheduleType.weeklyTarget ||
        (widget.habit.trackingType == TrackingType.counter &&
            widget.habit.counterGoalPeriod == CounterGoalPeriod.weekly);
  }

  DateTime _getWeekStart(DateTime date) {
    final normalizedDate = _dateOnly(date);

    return normalizedDate.subtract(Duration(days: normalizedDate.weekday - 1));
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime get _today => _dateOnly(DateTime.now());

  DateTime get _createdDate => _dateOnly(widget.habit.createdAt);

  HabitProgress? _getProgressForDate(DateTime date) {
    final normalizedDate = _dateOnly(date);

    for (final progress in _progressHistory) {
      if (_dateOnly(progress.date) == normalizedDate) return progress;
    }

    return null;
  }

  bool _isProgressSuccessful(HabitProgress? progress) {
    if (progress == null) return false;

    if (widget.habit.trackingType == TrackingType.completion) {
      return progress.isCompleted;
    }

    if (widget.habit.counterGoalPeriod == CounterGoalPeriod.weekly) {
      return progress.count > 0;
    }

    final goal = widget.habit.counterGoal;
    return goal == null ? progress.count > 0 : progress.count >= goal;
  }

  bool _isWeeklyTargetSession(HabitProgress? progress) {
    if (progress == null) return false;

    if (widget.habit.trackingType == TrackingType.completion) {
      return progress.isCompleted;
    }

    if (widget.habit.counterGoalPeriod == CounterGoalPeriod.weekly) {
      return progress.count > 0;
    }

    final goal = widget.habit.counterGoal;

    return goal == null ? progress.count > 0 : progress.count >= goal;
  }

  List<HabitProgress> _progressInRange(DateTime start, DateTime end) {
    return _progressHistory.where((progress) {
      final date = _dateOnly(progress.date);
      return !date.isBefore(start) &&
          !date.isAfter(end) &&
          !date.isBefore(_createdDate) &&
          !date.isAfter(_today);
    }).toList();
  }

  int _getWeeklyScheduledDays(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    var days = 0;

    for (
      var date = weekStart;
      !date.isAfter(end);
      date = date.add(const Duration(days: 1))
    ) {
      if (date.isBefore(_createdDate)) continue;
      if (widget.habit.isScheduledFor(date)) days++;
    }

    return days;
  }

  int _getWeeklyCompletedDays(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    final effectiveEnd = end.isBefore(_today) ? end : _today;
    var days = 0;

    for (
      var date = weekStart;
      !date.isAfter(effectiveEnd);
      date = date.add(const Duration(days: 1))
    ) {
      if (date.isBefore(_createdDate) || !widget.habit.isScheduledFor(date)) {
        continue;
      }

      if (_isProgressSuccessful(_getProgressForDate(date))) days++;
    }

    return days;
  }

  int _getWeeklyCounterTotal(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    final effectiveEnd = end.isBefore(_today) ? end : _today;

    return _progressInRange(weekStart, effectiveEnd)
        .where((progress) => widget.habit.isScheduledFor(progress.date))
        .fold<int>(0, (total, progress) => total + progress.count);
  }

  int _getWeeklyTargetSessions(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    final effectiveEnd = end.isBefore(_today) ? end : _today;

    return _progressInRange(
      weekStart,
      effectiveEnd,
    ).where(_isWeeklyTargetSession).length;
  }

  double _getWeeklyProgressPercentage(DateTime weekStart) {
    final isWeeklyCounter =
        widget.habit.trackingType == TrackingType.counter &&
        widget.habit.counterGoalPeriod == CounterGoalPeriod.weekly &&
        widget.habit.counterGoal != null &&
        widget.habit.counterGoal! > 0;
    final isWeeklyTarget =
        widget.habit.scheduleType == HabitScheduleType.weeklyTarget;

    if (isWeeklyTarget) {
      if (widget.habit.weeklyTarget <= 0) return 0;
      return (_getWeeklyTargetSessions(weekStart) /
              widget.habit.weeklyTarget *
              100)
          .clamp(0.0, 100.0);
    }

    if (isWeeklyCounter) {
      return (_getWeeklyCounterTotal(weekStart) /
              widget.habit.counterGoal! *
              100)
          .clamp(0.0, 100.0);
    }

    final expectedDays = _getWeeklyScheduledDays(weekStart);
    if (expectedDays == 0) return 0;
    return (_getWeeklyCompletedDays(weekStart) / expectedDays * 100).clamp(
      0.0,
      100.0,
    );
  }

  DateTime _getFirstFullWeekStart() {
    final createdWeek = _getWeekStart(widget.habit.createdAt);

    if (widget.habit.createdAt.weekday == DateTime.monday) {
      return createdWeek;
    }

    return createdWeek.add(const Duration(days: 7));
  }

  bool _isWeekSuccessful(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final today = DateTime.now();
    final effectiveWeekEnd = today.isBefore(weekEnd)
        ? DateTime(today.year, today.month, today.day)
        : weekEnd;

    final createdDate = DateTime(
      widget.habit.createdAt.year,
      widget.habit.createdAt.month,
      widget.habit.createdAt.day,
    );

    final relevantProgress = _progressHistory.where((progress) {
      final date = DateTime(
        progress.date.year,
        progress.date.month,
        progress.date.day,
      );

      return !date.isBefore(weekStart) &&
          !date.isAfter(effectiveWeekEnd) &&
          !date.isBefore(createdDate) &&
          !weekStart.isBefore(_getFirstFullWeekStart());
    }).toList();

    if (widget.habit.scheduleType == HabitScheduleType.weeklyTarget) {
      final successfulOccurrences = relevantProgress.where((progress) {
        if (widget.habit.trackingType == TrackingType.completion) {
          return progress.isCompleted;
        }

        if (widget.habit.counterGoalPeriod == CounterGoalPeriod.weekly) {
          return progress.count > 0;
        }

        final goal = widget.habit.counterGoal;

        return goal == null ? progress.count > 0 : progress.count >= goal;
      }).length;

      final meetsWeeklyTarget =
          successfulOccurrences >= widget.habit.weeklyTarget;

      if (widget.habit.trackingType == TrackingType.counter &&
          widget.habit.counterGoalPeriod == CounterGoalPeriod.weekly) {
        final totalCount = relevantProgress.fold<int>(
          0,
          (total, progress) => total + progress.count,
        );

        return meetsWeeklyTarget &&
            totalCount >= (widget.habit.counterGoal ?? 0);
      }

      return meetsWeeklyTarget;
    }

    final totalCount = relevantProgress.fold(
      0,
      (total, progress) => total + progress.count,
    );

    final goal = widget.habit.counterGoal;

    return goal == null ? totalCount > 0 : totalCount >= goal;
  }

  int _getCurrentStreak() {
    if (_usesWeeklyStreak()) {
      final today = DateTime.now();
      final currentWeek = _getWeekStart(today);
      final createdWeek = _getFirstFullWeekStart();

      int streak = 0;
      DateTime week = currentWeek;

      if (today.weekday != DateTime.sunday && !_isWeekSuccessful(currentWeek)) {
        week = week.subtract(const Duration(days: 7));
      }

      while (!week.isBefore(createdWeek)) {
        if (!_isWeekSuccessful(week)) {
          break;
        }

        streak++;
        week = week.subtract(const Duration(days: 7));
      }

      return streak;
    }
    final today = DateTime.now();
    final createdDate = DateTime(
      widget.habit.createdAt.year,
      widget.habit.createdAt.month,
      widget.habit.createdAt.day,
    );

    final progressByDate = {
      for (final progress in _progressHistory)
        DateTime(progress.date.year, progress.date.month, progress.date.day):
            progress,
    };

    bool isSuccessful(DateTime date) {
      final progress = progressByDate[date];

      if (progress == null) return false;

      if (widget.habit.trackingType == TrackingType.completion) {
        return progress.isCompleted;
      }

      final goal = widget.habit.counterGoal;

      return goal == null ? progress.count > 0 : progress.count >= goal;
    }

    int streak = 0;
    DateTime date = DateTime(today.year, today.month, today.day);

    while (!date.isBefore(createdDate)) {
      if (widget.habit.isScheduledFor(date)) {
        if (!isSuccessful(date)) {
          break;
        }

        streak++;
      }

      date = date.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int _getBestStreak() {
    if (_usesWeeklyStreak()) {
      final today = DateTime.now();
      final createdWeek = _getFirstFullWeekStart();
      final currentWeek = _getWeekStart(today);

      int currentStreak = 0;
      int bestStreak = 0;

      DateTime week = createdWeek;

      while (!week.isAfter(currentWeek)) {
        final isCurrentWeek = week == currentWeek;

        // Ignore an unfinished current week.
        if (isCurrentWeek &&
            today.weekday != DateTime.sunday &&
            !_isWeekSuccessful(week)) {
          break;
        }

        if (_isWeekSuccessful(week)) {
          currentStreak++;

          if (currentStreak > bestStreak) {
            bestStreak = currentStreak;
          }
        } else {
          currentStreak = 0;
        }

        week = week.add(const Duration(days: 7));
      }

      return bestStreak;
    }
    final createdDate = DateTime(
      widget.habit.createdAt.year,
      widget.habit.createdAt.month,
      widget.habit.createdAt.day,
    );

    final today = DateTime.now();
    int currentStreak = 0;
    int bestStreak = 0;

    final progressByDate = {
      for (final progress in _progressHistory)
        DateTime(progress.date.year, progress.date.month, progress.date.day):
            progress,
    };

    DateTime date = createdDate;

    while (!date.isAfter(today)) {
      if (widget.habit.isScheduledFor(date)) {
        final progress = progressByDate[date];

        final isSuccessful =
            progress != null &&
            (widget.habit.trackingType == TrackingType.completion
                ? progress.isCompleted
                : widget.habit.counterGoal == null
                ? progress.count > 0
                : progress.count >= widget.habit.counterGoal!);

        if (isSuccessful) {
          currentStreak++;
          if (currentStreak > bestStreak) {
            bestStreak = currentStreak;
          }
        } else {
          currentStreak = 0;
        }
      }

      date = date.add(const Duration(days: 1));
    }

    return bestStreak;
  }

  String _getScheduleDescription() {
    switch (widget.habit.scheduleType) {
      case HabitScheduleType.everyDay:
        return 'Every day';

      case HabitScheduleType.selectedDays:
        const days = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];

        return widget.habit.selectedWeekdays
            .map((day) => days[day - 1])
            .join(', ');

      case HabitScheduleType.everyNDays:
        return 'Every ${widget.habit.everyNDays} days';

      case HabitScheduleType.weeklyTarget:
        return '${widget.habit.weeklyTarget} times per week';
    }
  }

  String _getTrackingDescription() {
    return widget.habit.trackingType == TrackingType.completion
        ? 'Completion-based'
        : 'Counter-based';
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

  String _dateLabel(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getCalendarStatus(DateTime date, HabitProgress? progress) {
    final normalizedDate = _dateOnly(date);
    final isFuture = normalizedDate.isAfter(_today);
    final isToday = normalizedDate == _today;
    final isScheduled = widget.habit.isScheduledFor(normalizedDate);
    final isWeeklyTarget =
        widget.habit.scheduleType == HabitScheduleType.weeklyTarget;
    final isWeeklyCounter =
        widget.habit.trackingType == TrackingType.counter &&
        widget.habit.counterGoalPeriod == CounterGoalPeriod.weekly;

    if (normalizedDate.isBefore(_createdDate)) return 'Before habit';
    if (isFuture) {
      return isScheduled ? 'Upcoming' : 'Not scheduled';
    }

    if (!isScheduled && !isWeeklyTarget) {
      return 'Not scheduled';
    }

    if (isWeeklyTarget) {
      if (progress == null) {
        return isToday ? 'In progress' : 'No session recorded';
      }
      if (widget.habit.trackingType == TrackingType.completion) {
        return progress.isCompleted
            ? 'Completed'
            : isToday
            ? 'In progress'
            : 'No session recorded';
      }
      if (_isWeeklyTargetSession(progress)) {
        return 'Session recorded';
      }

      return isToday && progress.count > 0
          ? 'In progress'
          : 'No session recorded';
    }

    if (isWeeklyCounter) {
      if (progress != null && progress.count > 0) {
        final weekStart = _getWeekStart(normalizedDate);
        final goal = widget.habit.counterGoal;
        final total = _getWeeklyCounterTotal(weekStart);
        return goal != null && goal > 0 && total >= goal
            ? 'Weekly goal met'
            : 'Progress recorded';
      }
      return isToday ? 'In progress' : 'No progress recorded';
    }

    if (progress != null && _isProgressSuccessful(progress)) {
      return 'Completed';
    }
    if (isToday) return 'In progress';
    return 'Missed';
  }

  Color _getCalendarStatusColor(String status) {
    switch (status) {
      case 'Completed':
      case 'Weekly goal met':
      case 'Session recorded':
        return AppColors.primary;
      case 'Missed':
        return AppColors.danger;
      case 'In progress':
      case 'Progress recorded':
        return AppColors.warning;
      case 'Upcoming':
        return AppColors.textMuted;
      default:
        return AppColors.border;
    }
  }

  void _changeVisibleMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
      _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month);
    });
  }

  Widget _buildWeeklyProgressCard() {
    final weekStart = _getWeekStart(_today);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final isWeeklyTarget =
        widget.habit.scheduleType == HabitScheduleType.weeklyTarget;
    final isWeeklyCounter =
        widget.habit.trackingType == TrackingType.counter &&
        widget.habit.counterGoalPeriod == CounterGoalPeriod.weekly &&
        widget.habit.counterGoal != null &&
        widget.habit.counterGoal! > 0;
    final isWeeklyCounterHabit =
        widget.habit.trackingType == TrackingType.counter &&
        widget.habit.counterGoalPeriod == CounterGoalPeriod.weekly;
    final dailyCounter =
        widget.habit.trackingType == TrackingType.counter &&
        widget.habit.counterGoalPeriod == CounterGoalPeriod.daily;
    final weeklyTargetSessions = _getWeeklyTargetSessions(weekStart);
    final weeklyCounterTotal = _getWeeklyCounterTotal(weekStart);
    final expectedDays = _getWeeklyScheduledDays(weekStart);
    final completedDays = _getWeeklyCompletedDays(weekStart);
    final weeklyGoal = widget.habit.counterGoal;
    final weeklyGoalReached =
        weeklyGoal != null && weeklyCounterTotal >= weeklyGoal;
    final weekActivityTotal =
        _progressInRange(weekStart, _today.isBefore(weekEnd) ? _today : weekEnd)
            .where((progress) => widget.habit.isScheduledFor(progress.date))
            .fold<int>(0, (total, progress) => total + progress.count);
    final percentage = _getWeeklyProgressPercentage(weekStart);
    final description = isWeeklyTarget
        ? _remainingDescription(
            widget.habit.weeklyTarget - weeklyTargetSessions,
            'session',
            'sessions',
            'Weekly session target reached',
          )
        : isWeeklyCounter && weeklyGoal != null
        ? _remainingDescription(
            weeklyGoal - weeklyCounterTotal,
            widget.habit.counterUnit,
            widget.habit.counterUnit,
            'Weekly goal reached',
          )
        : _remainingDescription(
            expectedDays - completedDays,
            'scheduled day',
            'scheduled days',
            'All scheduled days completed',
          );
    final dailyGoalDays = dailyCounter && widget.habit.counterGoal != null
        ? _getWeeklyCompletedDays(weekStart)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This Week',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${weekStart.month}/${weekStart.day} – ${weekEnd.month}/${weekEnd.day}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${percentage.round()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: AppColors.surfaceElevated,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          if (isWeeklyTarget) ...[
            Text(
              '$weeklyTargetSessions / ${widget.habit.weeklyTarget} sessions',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isWeeklyCounter && weeklyGoal != null) ...[
              const SizedBox(height: 8),
              _buildSecondaryWeeklyMetric(
                '$weeklyCounterTotal / $weeklyGoal ${widget.habit.counterUnit}',
                (weeklyCounterTotal / weeklyGoal * 100).clamp(0.0, 100.0),
                _remainingDescription(
                  weeklyGoal - weeklyCounterTotal,
                  widget.habit.counterUnit,
                  widget.habit.counterUnit,
                  'Weekly counter goal reached',
                ),
              ),
            ] else if (isWeeklyCounterHabit) ...[
              const SizedBox(height: 4),
              Text(
                '$weekActivityTotal ${widget.habit.counterUnit} recorded this week',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
            if (weeklyTargetSessions < widget.habit.weeklyTarget)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
          ] else if (isWeeklyCounter && weeklyGoal != null) ...[
            Text(
              '$weeklyCounterTotal / $weeklyGoal ${widget.habit.counterUnit}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              weeklyGoalReached
                  ? 'Weekly goal reached'
                  : '${weeklyGoal - weeklyCounterTotal} ${widget.habit.counterUnit} remaining',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ] else if (dailyCounter) ...[
            Text(
              '$weekActivityTotal ${widget.habit.counterUnit} recorded this week',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.habit.counterGoal == null
                  ? '$completedDays / $expectedDays active scheduled days'
                  : '$completedDays / $expectedDays daily goals reached',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ] else if (isWeeklyCounterHabit) ...[
            Text(
              '$weekActivityTotal ${widget.habit.counterUnit} recorded this week',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$completedDays / $expectedDays active scheduled days',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ] else ...[
            Text(
              isWeeklyTarget
                  ? '$weeklyTargetSessions / ${widget.habit.weeklyTarget} sessions'
                  : widget.habit.scheduleType == HabitScheduleType.weeklyTarget
                  ? '$weeklyTargetSessions / ${widget.habit.weeklyTarget} sessions'
                  : '$completedDays / $expectedDays scheduled days completed',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (!isWeeklyTarget &&
              !isWeeklyCounter &&
              !isWeeklyCounterHabit &&
              !dailyCounter)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          if (dailyCounter && widget.habit.counterGoal != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                _remainingDescription(
                  expectedDays - (dailyGoalDays ?? 0),
                  'daily goal',
                  'daily goals',
                  'All scheduled daily goals reached',
                ),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(7, (index) {
              final date = weekStart.add(Duration(days: index));
              return Expanded(
                child: _buildWeekDayIndicator(
                  date,
                  isWeeklyTarget: isWeeklyTarget,
                  isWeeklyCounter: isWeeklyCounter,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _remainingDescription(
    int remaining,
    String singular,
    String plural,
    String completeMessage,
  ) {
    if (remaining <= 0) return completeMessage;
    return '$remaining ${remaining == 1 ? singular : plural} remaining';
  }

  Widget _buildSecondaryWeeklyMetric(
    String label,
    double percentage,
    String remaining,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: percentage / 100,
          minHeight: 5,
          borderRadius: BorderRadius.circular(6),
          backgroundColor: AppColors.surfaceElevated,
          color: AppColors.primaryMuted,
        ),
        const SizedBox(height: 3),
        Text(
          remaining,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildWeekDayIndicator(
    DateTime date, {
    required bool isWeeklyTarget,
    required bool isWeeklyCounter,
  }) {
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final progress = _getProgressForDate(date);
    final isScheduled = widget.habit.isScheduledFor(date);
    final isFuture = date.isAfter(_today);
    final isToday = date == _today;
    final count = progress?.count ?? 0;

    String status;
    Color color;
    IconData? icon;
    if (date.isBefore(_createdDate) || !isScheduled) {
      status = 'Not scheduled';
      color = AppColors.border;
    } else if (isFuture) {
      status = 'Upcoming';
      color = AppColors.textMuted;
    } else if (isWeeklyTarget) {
      if (progress != null && _isWeeklyTargetSession(progress)) {
        status = 'Session recorded';
        color = AppColors.primary;
        icon = Icons.check;
      } else {
        status = isToday ? 'In progress' : 'No session recorded';
        color = isToday ? AppColors.warning : AppColors.textMuted;
      }
    } else if (isWeeklyCounter) {
      if (count > 0) {
        status = 'Progress recorded';
        color = AppColors.warning;
        icon = Icons.more_horiz;
      } else {
        status = isToday ? 'In progress' : 'No progress recorded';
        color = isToday ? AppColors.warning : AppColors.textMuted;
      }
    } else if (_isProgressSuccessful(progress)) {
      status = 'Completed';
      color = AppColors.primary;
      icon = Icons.check;
    } else if (isToday) {
      status = 'In progress';
      color = AppColors.warning;
      icon = Icons.more_horiz;
    } else {
      status = 'Missed';
      color = AppColors.danger;
      icon = Icons.close;
    }

    final label =
        '${weekdayLabels[date.weekday - 1]}, ${date.month}/${date.day}: $status'
        '${widget.habit.trackingType == TrackingType.counter ? ', $count ${widget.habit.counterUnit}' : ''}';
    return Semantics(
      label: label,
      child: Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Column(
            children: [
              Text(
                weekdayLabels[date.weekday - 1],
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: color == AppColors.border ? 0.3 : 0.18,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.8)),
                ),
                child: Icon(
                  icon ?? (status == 'Upcoming' ? Icons.circle_outlined : null),
                  size: 15,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.habit.trackingType == TrackingType.counter && count > 0
                    ? '$count'
                    : '${date.day}',
                maxLines: 1,
                style: TextStyle(
                  color: isToday ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCalendar() {
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final leadingDays = firstOfMonth.weekday - 1;
    final cellCount = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Completion history',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => _changeVisibleMonth(-1),
                icon: const Icon(Icons.chevron_left),
                color: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                _monthLabel(_visibleMonth),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () => _changeVisibleMonth(1),
                icon: const Icon(Icons.chevron_right),
                color: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final day = index - leadingDays + 1;
              if (day < 1 || day > daysInMonth) return const SizedBox();
              return _buildCalendarDayCell(
                DateTime(_visibleMonth.year, _visibleMonth.month, day),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildCalendarLegend(),
          const SizedBox(height: 12),
          _buildSelectedDateDetails(),
        ],
      ),
    );
  }

  Widget _buildCalendarDayCell(DateTime date) {
    final normalizedDate = _dateOnly(date);
    final progress = _getProgressForDate(normalizedDate);
    final status = _getCalendarStatus(normalizedDate, progress);
    final statusColor = _getCalendarStatusColor(status);
    final isSelected = normalizedDate == _selectedDate;
    final countLabel =
        widget.habit.trackingType == TrackingType.counter &&
            progress != null &&
            progress.count > 0
        ? '${progress.count}'
        : null;

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${_dateLabel(normalizedDate)}: $status${countLabel == null ? '' : ', $countLabel ${widget.habit.counterUnit}'}',
      child: Tooltip(
        message: '${_dateLabel(normalizedDate)}: $status',
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _selectedDate = normalizedDate),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.surfaceElevated
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${normalizedDate.day}',
                  style: TextStyle(
                    color: normalizedDate.isBefore(_createdDate)
                        ? AppColors.textMuted.withValues(alpha: 0.45)
                        : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 2),
                if (countLabel != null)
                  Text(
                    countLabel,
                    maxLines: 1,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 8,
                      height: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (status != 'Not scheduled' &&
                    status != 'Before habit' &&
                    status != 'No session recorded' &&
                    status != 'No progress recorded')
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarLegend() {
    final isWeeklyCounter =
        widget.habit.trackingType == TrackingType.counter &&
        widget.habit.counterGoalPeriod == CounterGoalPeriod.weekly;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        _buildLegendItem('Completed', AppColors.primary),
        _buildLegendItem('Missed', AppColors.danger),
        if (isWeeklyCounter)
          _buildLegendItem('Progress recorded', AppColors.warning),
        _buildLegendItem('Upcoming', AppColors.textMuted),
        _buildLegendItem('Not scheduled', AppColors.border),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSelectedDateDetails() {
    final date = _selectedDate;
    final progress = _getProgressForDate(date);
    final status = _getCalendarStatus(date, progress);
    final weeklyTarget =
        widget.habit.scheduleType == HabitScheduleType.weeklyTarget;
    final weeklyCounter =
        widget.habit.trackingType == TrackingType.counter &&
        widget.habit.counterGoalPeriod == CounterGoalPeriod.weekly;
    final detailLines = <String>[];

    if (date.isBefore(_createdDate)) {
      detailLines.add('This date is before the habit was created.');
    } else if (weeklyTarget) {
      if (widget.habit.trackingType == TrackingType.counter) {
        detailLines.add(
          'Recorded: ${progress?.count ?? 0} ${widget.habit.counterUnit}',
        );
        detailLines.add(
          _isWeeklyTargetSession(progress)
              ? 'This day qualifies as a session.'
              : status == 'Upcoming'
              ? 'This session day is upcoming.'
              : 'No successful session recorded on this day.',
        );
      } else {
        detailLines.add(
          status == 'Upcoming'
              ? 'A session day is upcoming.'
              : progress?.isCompleted == true
              ? 'The habit was completed.'
              : 'No session recorded on this day.',
        );
      }
      final weekStart = _getWeekStart(date);
      detailLines.add(
        '${_getWeeklyTargetSessions(weekStart)} / ${widget.habit.weeklyTarget} sessions this week',
      );
      if (widget.habit.trackingType == TrackingType.counter &&
          weeklyCounter &&
          widget.habit.counterGoal != null) {
        final weekTotal = _getWeeklyCounterTotal(weekStart);
        final counterGoalMet = weekTotal >= widget.habit.counterGoal!;
        detailLines.add(
          'Weekly counter: $weekTotal / ${widget.habit.counterGoal} ${widget.habit.counterUnit}${counterGoalMet ? ' — goal met' : ''}',
        );
      } else if (widget.habit.trackingType == TrackingType.counter &&
          widget.habit.counterGoal != null) {
        detailLines.add(
          'Daily goal: ${widget.habit.counterGoal} ${widget.habit.counterUnit}',
        );
      }
    } else if (widget.habit.trackingType == TrackingType.completion) {
      detailLines.add(
        progress?.isCompleted == true
            ? 'The habit was completed.'
            : status == 'Not scheduled'
            ? 'This habit was not scheduled.'
            : status == 'Upcoming'
            ? 'This scheduled day is upcoming.'
            : 'The habit was not completed.',
      );
    } else {
      detailLines.add(
        'Recorded: ${progress?.count ?? 0} ${widget.habit.counterUnit}',
      );
      if (weeklyCounter && widget.habit.counterGoal != null) {
        final weekTotal = _getWeeklyCounterTotal(_getWeekStart(date));
        detailLines.add(
          'This week: $weekTotal / ${widget.habit.counterGoal} ${widget.habit.counterUnit}',
        );
      } else if (widget.habit.counterGoal != null) {
        detailLines.add(
          'Daily goal: ${widget.habit.counterGoal} ${widget.habit.counterUnit}',
        );
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _dateLabel(date),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: _getCalendarStatusColor(status),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ...detailLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                line,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Habit details'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit habit',
            onPressed: () async {
              final updatedHabit = await Navigator.push<Habit>(
                context,
                MaterialPageRoute(
                  builder: (context) => AddHabitScreen(habit: widget.habit),
                ),
              );

              if (updatedHabit != null && context.mounted) {
                Navigator.pop(context, updatedHabit);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete habit',
            onPressed: () async {
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Delete habit?'),
                  content: Text(
                    'Are you sure you want to delete "${widget.habit.name}"? '
                    'Its progress history will also be deleted. '
                    'This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              );

              if (shouldDelete != true || !context.mounted) return;

              final deleted =
                  await widget.onHabitDeleted?.call(widget.habit.id) ?? false;

              if (deleted && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 90,
                height: 90,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.habit.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  widget.habit.emoji,
                  style: const TextStyle(fontSize: 42),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                widget.habit.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (widget.habit.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Center(
                child: Text(
                  widget.habit.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            const Text(
              'Statistics',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoadingProgress)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      widget.habit.trackingType == TrackingType.completion
                          ? 'Total completions'
                          : 'Total ${widget.habit.counterUnit}',
                      _getTotalCompletions().toString(),
                    ),
                    const SizedBox(height: 12),

                    if (widget.habit.trackingType == TrackingType.counter) ...[
                      _buildStatRow(
                        'Highest in a day',
                        '${_getHighestDailyCount()} ${widget.habit.counterUnit}',
                      ),
                      const SizedBox(height: 12),
                    ],

                    _buildStatRow(
                      'Current streak',
                      '${_getCurrentStreak()} ${_getCurrentStreak() == 1 ? (_usesWeeklyStreak() ? 'week' : 'day') : (_usesWeeklyStreak() ? 'weeks' : 'days')}',
                    ),
                    const SizedBox(height: 12),

                    _buildStatRow(
                      'Best streak',
                      '${_getBestStreak()} ${_getBestStreak() == 1 ? (_usesWeeklyStreak() ? 'week' : 'day') : (_usesWeeklyStreak() ? 'weeks' : 'days')}',
                    ),
                  ],
                ),
              ),

            if (!_isLoadingProgress) ...[
              const SizedBox(height: 28),
              _buildWeeklyProgressCard(),
              const SizedBox(height: 12),
              _buildCompletionCalendar(),
            ],

            const SizedBox(height: 32),

            const Text(
              'Habit information',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            _buildInfoCard(
              icon: Icons.track_changes_outlined,
              title: 'Tracking type',
              value: _getTrackingDescription(),
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.calendar_today_outlined,
              title: 'Schedule',
              value: _getScheduleDescription(),
            ),

            if (widget.habit.trackingType == TrackingType.counter) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.flag_outlined,
                title: 'Counter goal',
                value: widget.habit.counterGoal == null
                    ? 'No goal set'
                    : '${widget.habit.counterGoal} ${widget.habit.counterUnit} '
                          '${widget.habit.counterGoalPeriod.name}',
              ),
            ],

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.event_outlined,
              title: 'Created on',
              value:
                  '${widget.habit.createdAt.month}/${widget.habit.createdAt.day}/${widget.habit.createdAt.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
