import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/calendar_dates.dart';
import '../../domain/models/habit.dart';
import 'add_habit_screen.dart';
import '../../data/datasources/habit_progress_local_data_source.dart';
import '../../domain/models/habit_progress.dart';
import '../widgets/habit_calendar.dart';
import '../widgets/habit_day_status.dart';
import '../widgets/habit_week_progress.dart';
import '../../domain/models/habit_icon.dart';

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
    return CalendarDates.startOfWeek(date);
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
      return progress.isCompleted;
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

  DateTime _getFirstFullWeekStart() {
    final createdWeek = _getWeekStart(widget.habit.createdAt);

    if (widget.habit.createdAt.weekday == DateTime.sunday) {
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
          widget.habit.isScheduledFor(date) &&
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

      if (today.weekday != DateTime.saturday &&
          !_isWeekSuccessful(currentWeek)) {
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
            today.weekday != DateTime.saturday &&
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

  HabitDayStatus _getCalendarStatus(DateTime date, HabitProgress? progress) {
    final normalizedDate = _dateOnly(date);
    final isScheduled = widget.habit.isScheduledFor(normalizedDate);
    final isWeeklyTarget =
        widget.habit.scheduleType == HabitScheduleType.weeklyTarget;
    final isWeeklyCounter =
        widget.habit.trackingType == TrackingType.counter &&
        widget.habit.counterGoalPeriod == CounterGoalPeriod.weekly;

    if (normalizedDate.isBefore(_createdDate)) {
      return HabitDayStatus.notScheduled;
    }
    if (normalizedDate.isAfter(_today)) {
      return isScheduled
          ? HabitDayStatus.upcoming
          : HabitDayStatus.notScheduled;
    }

    if (!isScheduled && !isWeeklyTarget) {
      return HabitDayStatus.notScheduled;
    }

    if (isWeeklyTarget) {
      return _isWeeklyTargetSession(progress)
          ? HabitDayStatus.completed
          : HabitDayStatus.notScheduled;
    }

    if (isWeeklyCounter) {
      return progress?.isCompleted == true
          ? HabitDayStatus.completed
          : HabitDayStatus.notScheduled;
    }

    if (progress != null && _isProgressSuccessful(progress)) {
      return HabitDayStatus.completed;
    }
    if (normalizedDate == _today) return HabitDayStatus.today;
    return HabitDayStatus.missed;
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'This Week',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            CalendarDates.weekRangeLabel(_getWeekStart(_today)),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          HabitWeekProgress(
            weekStart: _getWeekStart(_today),
            today: _today,
            statusForDate: _statusForDate,
            countForDate: (date) => _getProgressForDate(date)?.count,
            counterUnit: widget.habit.counterUnit,
            isCounter: widget.habit.trackingType == TrackingType.counter,
          ),
        ],
      ),
    );
  }

  HabitDayStatus _statusForDate(DateTime date) =>
      _getCalendarStatus(date, _getProgressForDate(date));

  Widget _buildCompletionCalendar() {
    return HabitCalendar(
      visibleMonth: _visibleMonth,
      selectedDate: _selectedDate,
      statusForDate: _statusForDate,
      countForDate: (date) => _getProgressForDate(date)?.count,
      counterUnit: widget.habit.counterUnit,
      isCounter: widget.habit.trackingType == TrackingType.counter,
      selectedDateDetails: _buildSelectedDateDetails(),
      onDateSelected: (date) => setState(() => _selectedDate = date),
      onMonthChanged: _changeVisibleMonth,
    );
  }

  Widget _buildSelectedDateDetails() {
    final date = _selectedDate;
    final progress = _getProgressForDate(date);
    final status = _getCalendarStatus(date, progress);
    final count = widget.habit.trackingType == TrackingType.counter
        ? progress?.count
        : null;
    final dailyCounterGoal =
        widget.habit.trackingType == TrackingType.counter &&
        widget.habit.counterGoalPeriod == CounterGoalPeriod.daily &&
        widget.habit.counterGoal != null;
    final counterDetails = count == null
        ? null
        : dailyCounterGoal
        ? '$count / ${widget.habit.counterGoal} ${widget.habit.counterUnit}'
        : '$count ${widget.habit.counterUnit}';

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
              if (status != HabitDayStatus.today)
                Text(
                  status.label,
                  style: TextStyle(
                    color: status == HabitDayStatus.completed
                        ? AppColors.primary
                        : status == HabitDayStatus.missed
                        ? AppColors.danger
                        : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (counterDetails != null) ...[
            const SizedBox(height: 5),
            Text(
              counterDetails,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
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
                child: Icon(
                  HabitIconCatalog.getByKey(widget.habit.iconKey).icon,
                  color: widget.habit.color,
                  size: 42,
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
                padding: const EdgeInsets.all(14),
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
                    const SizedBox(height: 9),

                    if (widget.habit.trackingType == TrackingType.counter) ...[
                      _buildStatRow(
                        'Highest in a day',
                        '${_getHighestDailyCount()} ${widget.habit.counterUnit}',
                      ),
                      const SizedBox(height: 9),
                    ],

                    _buildStatRow(
                      'Current streak',
                      '${_getCurrentStreak()} ${_getCurrentStreak() == 1 ? (_usesWeeklyStreak() ? 'week' : 'day') : (_usesWeeklyStreak() ? 'weeks' : 'days')}',
                    ),
                    const SizedBox(height: 9),

                    _buildStatRow(
                      'Best streak',
                      '${_getBestStreak()} ${_getBestStreak() == 1 ? (_usesWeeklyStreak() ? 'week' : 'day') : (_usesWeeklyStreak() ? 'weeks' : 'days')}',
                    ),
                  ],
                ),
              ),

            if (!_isLoadingProgress) ...[
              const SizedBox(height: 12),
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
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
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
