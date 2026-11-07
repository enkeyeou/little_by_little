import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/calendar_dates.dart';
import '../../../habits/domain/models/habit.dart';
import '../../../habits/data/datasources/habit_progress_local_data_source.dart';
import '../../../habits/domain/models/habit_progress.dart';
import '../../../habits/presentation/screens/habit_details_screen.dart';
import '../widgets/monthly_activity_card.dart';
import '../widgets/progress_overview_pager.dart';
import '../widgets/today_progress_card.dart';
import '../widgets/weekly_progress_card.dart';

class HomeScreen extends StatefulWidget {
  final List<Habit> habits;
  final Future<void> Function(Habit habit)? onHabitUpdated;
  final Future<bool> Function(String id)? onHabitDeleted;

  const HomeScreen({
    super.key,
    required this.habits,
    this.onHabitUpdated,
    this.onHabitDeleted,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HabitProgressLocalDataSource _progressDataSource =
      HabitProgressLocalDataSource();

  final Map<String, HabitProgress> _todayProgress = {};
  final Map<String, int> _weeklyCounts = {};
  final Map<String, int> _weeklyTargetCounts = {};
  Map<DateTime, Map<String, HabitProgress>> _activityByDate = {};
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _progressPage = 0;
  int _progressRequestId = 0;
  late String _habitConfigurationSignature;

  @override
  void initState() {
    super.initState();
    _habitConfigurationSignature = _getHabitConfigurationSignature();
    _refreshProgressData();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final signature = _getHabitConfigurationSignature();
    if (signature == _habitConfigurationSignature) return;
    _habitConfigurationSignature = signature;
    _refreshProgressData();
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime get _today => _dateOnly(DateTime.now());

  String _getHabitConfigurationSignature() =>
      widget.habits.map((habit) => habit.toMap().toString()).join('|');

  DateTime _getWeekStart(DateTime date) {
    return CalendarDates.startOfWeek(date);
  }

  Future<void> _refreshProgressData() async {
    final requestId = ++_progressRequestId;
    final generation = _habitConfigurationSignature;
    final history = await _progressDataSource.getProgressForHabits(
      widget.habits.map((habit) => habit.id).toList(),
    );

    if (!mounted ||
        requestId != _progressRequestId ||
        generation != _habitConfigurationSignature) {
      return;
    }
    _applyLoadedProgress(history);
  }

  void _applyLoadedProgress(List<HabitProgress> activityProgress) {
    final progressByDate = <DateTime, Map<String, HabitProgress>>{};
    for (final progress in activityProgress) {
      progressByDate.putIfAbsent(
        _dateOnly(progress.date),
        () => {},
      )[progress.habitId] = progress;
    }

    setState(() {
      _todayProgress.clear();
      _weeklyCounts.clear();
      _weeklyTargetCounts.clear();

      final weekStart = _getWeekStart(_today);
      final weekEnd = weekStart.add(const Duration(days: 6));
      for (final item in activityProgress) {
        final itemDate = _dateOnly(item.date);
        if (itemDate.isAfter(_today)) continue;
        if (itemDate == _today) {
          _todayProgress[item.habitId] = item;
        }

        if (itemDate.isBefore(weekStart) || itemDate.isAfter(weekEnd)) {
          continue;
        }

        final habit = _habitById(item.habitId);
        if (habit == null ||
            itemDate.isBefore(_dateOnly(habit.createdAt)) ||
            !habit.isScheduledFor(item.date)) {
          continue;
        }

        _weeklyCounts.update(
          item.habitId,
          (count) => count + item.count,
          ifAbsent: () => item.count,
        );
        if (_isSuccessfulSession(habit, item)) {
          _weeklyTargetCounts.update(
            item.habitId,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }

      _activityByDate = progressByDate;
    });
  }

  Habit? _habitById(String habitId) {
    for (final habit in widget.habits) {
      if (habit.id == habitId) return habit;
    }
    return null;
  }

  bool _isSuccessfulSession(Habit habit, HabitProgress? progress) {
    if (progress == null) return false;
    if (habit.trackingType == TrackingType.completion) {
      return progress.isCompleted;
    }
    if (habit.counterGoalPeriod == CounterGoalPeriod.weekly) {
      return progress.count > 0;
    }
    final goal = habit.counterGoal;
    return goal == null ? progress.count > 0 : progress.count >= goal;
  }

  bool _isDailyActivitySuccessful(Habit habit, HabitProgress? progress) {
    if (habit.trackingType == TrackingType.counter &&
        habit.counterGoalPeriod == CounterGoalPeriod.weekly) {
      return progress?.isCompleted ?? false;
    }
    return _isSuccessfulSession(habit, progress);
  }

  bool _isCompleted(String habitId) {
    return _todayProgress[habitId]?.isCompleted ?? false;
  }

  List<Habit> get _todaysHabits {
    return widget.habits
        .where(
          (habit) =>
              !_today.isBefore(_dateOnly(habit.createdAt)) &&
              habit.isScheduledFor(_today),
        )
        .toList();
  }

  int _getTodaySuccessfulHabits() => _getDaySummary(_today).successful;

  int _getTodayCount(String habitId) {
    return _todayProgress[habitId]?.count ?? 0;
  }

  bool _isCounterGoalReached(Habit habit) {
    if (habit.trackingType != TrackingType.counter ||
        habit.counterGoal == null) {
      return false;
    }

    final currentCount = habit.counterGoalPeriod == CounterGoalPeriod.daily
        ? _getTodayCount(habit.id)
        : _weeklyCounts[habit.id] ?? 0;

    return currentCount >= habit.counterGoal!;
  }

  bool _isWeeklyTargetReached(Habit habit) {
    if (habit.scheduleType != HabitScheduleType.weeklyTarget) {
      return false;
    }

    final completedOccurrences = _weeklyTargetCounts[habit.id] ?? 0;

    return completedOccurrences >= habit.weeklyTarget;
  }

  void _changeActivityMonth(int offset) {
    final nextMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + offset,
    );
    final currentMonth = DateTime(_today.year, _today.month);
    if (nextMonth.isAfter(currentMonth)) return;

    setState(() {
      _visibleMonth = nextMonth;
    });
  }

  void _selectProgressPage(int page) {
    if (page == _progressPage) return;
    setState(() => _progressPage = page);
  }

  HabitProgress? _getActivityProgress(Habit habit, DateTime date) {
    final normalizedDate = _dateOnly(date);
    return _activityByDate[normalizedDate]?[habit.id];
  }

  List<Habit> _getApplicableHabits(DateTime date) {
    final normalizedDate = _dateOnly(date);
    return widget.habits
        .where(
          (habit) =>
              !normalizedDate.isBefore(_dateOnly(habit.createdAt)) &&
              habit.isScheduledFor(normalizedDate),
        )
        .toList();
  }

  ({int applicable, int successful}) _getDaySummary(DateTime date) {
    final normalizedDate = _dateOnly(date);
    if (normalizedDate.isAfter(_today)) {
      return (applicable: 0, successful: 0);
    }

    final habits = _getApplicableHabits(normalizedDate);
    var applicable = 0;
    var successful = 0;
    for (final habit in habits) {
      final progress = _getActivityProgress(habit, normalizedDate);
      final isWeeklyTarget =
          habit.scheduleType == HabitScheduleType.weeklyTarget;
      final isWeeklyCounter =
          habit.trackingType == TrackingType.counter &&
          habit.counterGoalPeriod == CounterGoalPeriod.weekly;
      if (isWeeklyTarget) {
        if (!_isSuccessfulSession(habit, progress)) continue;
      } else if (isWeeklyCounter && progress?.isCompleted != true) {
        continue;
      }

      applicable++;
      if (isWeeklyTarget || _isDailyActivitySuccessful(habit, progress)) {
        successful++;
      }
    }
    return (applicable: applicable, successful: successful);
  }

  int _getHeatLevel(DateTime date) {
    final summary = _getDaySummary(date);
    if (summary.applicable == 0) return -1;
    if (summary.successful == 0) return 0;

    final percentage = summary.successful / summary.applicable * 100;
    if (percentage < 25) return 1;
    if (percentage < 50) return 2;
    if (percentage < 75) return 3;
    if (percentage < 100) return 4;
    return 5;
  }

  int _getCurrentActivityStreak() {
    if (widget.habits.isEmpty) return 0;

    var date = _today;
    final todaySummary = _getDaySummary(date);
    if (todaySummary.applicable > 0 && todaySummary.successful == 0) {
      date = date.subtract(const Duration(days: 1));
    }

    final firstCreatedDate = widget.habits
        .map((habit) => _dateOnly(habit.createdAt))
        .reduce((first, created) => created.isBefore(first) ? created : first);
    var streak = 0;
    while (!date.isBefore(firstCreatedDate)) {
      final summary = _getDaySummary(date);
      if (summary.applicable == 0) {
        date = date.subtract(const Duration(days: 1));
        continue;
      }
      if (summary.successful == 0) break;
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _getActivityStreakMessage() {
    final streak = _getCurrentActivityStreak();
    if (streak == 0) return 'Start your streak today!';
    if (streak >= 7) return "You're on a $streak-day streak. Amazing!";
    return "You're on a $streak-day streak. Keep going!";
  }

  Widget _buildProgressOverviewCard() {
    return ProgressOverviewPager(
      currentPage: _progressPage,
      onPageChanged: _selectProgressPage,
      pages: [
        _buildTodayProgressPage(),
        _buildWeeklyProgressPage(),
        _buildMonthlyActivityPage(),
      ],
    );
  }

  Widget _buildTodayProgressPage() {
    return TodayProgressCard(
      completedHabits: _getTodaySuccessfulHabits(),
      scheduledHabits: _getDaySummary(_today).applicable,
    );
  }

  Widget _buildWeeklyProgressPage() {
    return WeeklyProgressCard(
      weekStart: _getWeekStart(_today),
      today: _today,
      getDaySummary: _getDaySummary,
    );
  }

  Widget _buildMonthlyActivityPage() {
    return MonthlyActivityCard(
      month: _visibleMonth,
      today: _today,
      streakMessage: _getActivityStreakMessage(),
      getActivityLevel: _getHeatLevel,
      getActivityDescription: _getActivityDescription,
      onMonthChanged: _changeActivityMonth,
    );
  }

  String _getActivityDescription(DateTime date) {
    if (date.isAfter(_today)) return 'Upcoming';
    final summary = _getDaySummary(date);
    if (summary.applicable == 0) return 'No scheduled activity';
    return '${summary.successful} of ${summary.applicable} completed';
  }

  Future<void> _toggleCompletion(Habit habit) async {
    final isNowCompleted = !_isCompleted(habit.id);

    final progress = HabitProgress(
      habitId: habit.id,
      date: DateTime.now(),
      isCompleted: isNowCompleted,
      count: _todayProgress[habit.id]?.count ?? 0,
    );

    await _progressDataSource.saveProgress(progress);

    if (!mounted) return;
    await _refreshProgressData();
  }

  Future<void> _updateCounter(Habit habit, int change) async {
    final currentCount = _getTodayCount(habit.id);
    final newCount = (currentCount + change).clamp(0, 999999);

    final weeklyCount =
        (_weeklyCounts[habit.id] ?? 0) - currentCount + newCount;

    final isCompleted =
        habit.counterGoal != null &&
        (habit.counterGoalPeriod == CounterGoalPeriod.daily
            ? newCount >= habit.counterGoal!
            : weeklyCount >= habit.counterGoal!);

    final progress = HabitProgress(
      habitId: habit.id,
      date: DateTime.now(),
      isCompleted: isCompleted,
      count: newCount,
    );

    await _progressDataSource.saveProgress(progress);

    if (!mounted) return;
    await _refreshProgressData();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good afternoon.',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Small steps still count.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.spa_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
              ],
            ),

            const SizedBox(height: 28),

            _buildProgressOverviewCard(),
            const SizedBox(height: 28),

            // Habits Section Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your habits',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${_todaysHabits.length} ${_todaysHabits.length == 1 ? 'habit' : 'habits'}',
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Habits List or Empty State
            if (_todaysHabits.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.spa_outlined,
                      color: AppColors.primary,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Start small. Grow steadily.',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Your habits will appear here. Begin with one small thing you'd like to do consistently.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._todaysHabits.map((habit) {
                return GestureDetector(
                  onTap: () async {
                    final updatedHabit = await Navigator.push<Habit>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HabitDetailsScreen(
                          habit: habit,
                          onHabitDeleted: widget.onHabitDeleted,
                        ),
                      ),
                    );

                    if (updatedHabit != null) {
                      await widget.onHabitUpdated?.call(updatedHabit);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: habit.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            habit.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              if (habit.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  habit.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              if (habit.scheduleType ==
                                  HabitScheduleType.weeklyTarget) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '${_weeklyTargetCounts[habit.id] ?? 0} / ${habit.weeklyTarget} times this week',
                                  style: TextStyle(
                                    color: _isWeeklyTargetReached(habit)
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (habit.trackingType == TrackingType.counter) ...[
                          IconButton(
                            onPressed: _getTodayCount(habit.id) > 0
                                ? () => _updateCounter(habit, -1)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppColors.textSecondary,
                          ),
                          Text(
                            '${habit.counterGoalPeriod == CounterGoalPeriod.weekly ? _weeklyCounts[habit.id] ?? 0 : _getTodayCount(habit.id)}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _updateCounter(habit, 1),
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppColors.primary,
                          ),
                          if (_isCounterGoalReached(habit))
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                            ),
                        ] else
                          IconButton(
                            onPressed: () => _toggleCompletion(habit),
                            icon: Icon(
                              _isCompleted(habit.id)
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: _isCompleted(habit.id)
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                            tooltip: _isCompleted(habit.id)
                                ? 'Mark as incomplete'
                                : 'Mark as complete',
                          ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
