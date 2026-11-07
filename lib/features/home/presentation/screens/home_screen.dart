import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../habits/domain/models/habit.dart';
import '../../../habits/data/datasources/habit_progress_local_data_source.dart';
import '../../../habits/domain/models/habit_progress.dart';
import '../../../habits/presentation/screens/habit_details_screen.dart';

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

  final PageController _progressPageController = PageController();
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

  @override
  void dispose() {
    _progressPageController.dispose();
    super.dispose();
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime get _today => _dateOnly(DateTime.now());

  String _getHabitConfigurationSignature() =>
      widget.habits.map((habit) => habit.toMap().toString()).join('|');

  DateTime _getWeekStart(DateTime date) {
    final normalizedDate = _dateOnly(date);
    return normalizedDate.subtract(
      Duration(days: normalizedDate.weekday - DateTime.monday),
    );
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
    _progressPageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
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
      if (habit.scheduleType == HabitScheduleType.weeklyTarget ||
          (habit.trackingType == TrackingType.counter &&
              habit.counterGoalPeriod == CounterGoalPeriod.weekly)) {
        if (!_isSuccessfulSession(habit, progress)) continue;
      }

      applicable++;
      if (_isDailyActivitySuccessful(habit, progress)) {
        successful++;
      }
    }
    return (applicable: applicable, successful: successful);
  }

  int _getHeatLevel(DateTime date) {
    final summary = _getDaySummary(date);
    if (summary.applicable == 0) return -1;
    if (_dateOnly(date) == _today && summary.successful == 0) return -1;
    if (summary.successful == 0) return 0;

    final percentage = summary.successful / summary.applicable * 100;
    if (percentage < 25) return 1;
    if (percentage < 50) return 2;
    if (percentage < 75) return 3;
    if (percentage < 100) return 4;
    return 5;
  }

  Color _getHeatColor(int level) {
    switch (level) {
      case 0:
        return AppColors.danger.withValues(alpha: 0.22);
      case 1:
        return AppColors.primary.withValues(alpha: 0.16);
      case 2:
        return AppColors.primary.withValues(alpha: 0.3);
      case 3:
        return AppColors.primary.withValues(alpha: 0.48);
      case 4:
        return AppColors.primary.withValues(alpha: 0.7);
      case 5:
        return AppColors.primary;
      default:
        return AppColors.surfaceElevated;
    }
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

  int _getCurrentActivityStreak() {
    if (widget.habits.isEmpty) return 0;

    var date = _today;
    final todaySummary = _getDaySummary(date);
    if (todaySummary.applicable > 0 &&
        todaySummary.successful < todaySummary.applicable) {
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
      if (summary.successful < summary.applicable) break;
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: switch (_progressPage) {
              0 => 130.0,
              1 => 160.0,
              _ => 255.0,
            },
            child: PageView(
              controller: _progressPageController,
              onPageChanged: (page) => setState(() => _progressPage = page),
              children: [
                _buildTodayProgressPage(),
                _buildWeeklyProgressPage(),
                _buildMonthlyActivityPage(),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProgressPageIndicator(0),
              const SizedBox(width: 8),
              _buildProgressPageIndicator(1),
              const SizedBox(width: 8),
              _buildProgressPageIndicator(2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPageIndicator(int page) {
    final isSelected = _progressPage == page;
    const labels = ["Today's progress", 'Weekly progress', 'Monthly activity'];
    return Semantics(
      button: true,
      label: labels[page],
      child: InkWell(
        key: ValueKey('progress-page-indicator-$page'),
        onTap: () => _selectProgressPage(page),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: isSelected ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayProgressPage() {
    final successful = _getTodaySuccessfulHabits();
    final dailyOpportunities = _getDaySummary(_today).applicable;
    final hasScheduledHabits = dailyOpportunities > 0;
    final progress = hasScheduledHabits ? successful / dailyOpportunities : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Today's Progress",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              hasScheduledHabits ? '${(progress * 100).round()}%' : '—',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (hasScheduledHabits) ...[
          Text(
            '$successful / $dailyOpportunities Habits Completed',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: AppColors.surfaceElevated,
            color: AppColors.primary,
          ),
        ] else ...[
          const SizedBox(height: 28),
          const Text(
            'No habits scheduled for today',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeeklyProgressPage() {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final weekStart = _getWeekStart(_today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Progress',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 17),
        LayoutBuilder(
          builder: (context, constraints) {
            final diameter = (constraints.maxWidth / 8).clamp(30.0, 40.0);
            return Row(
              children: List.generate(7, (index) {
                final date = weekStart.add(Duration(days: index));
                final summary = _getDaySummary(date);
                final isFuture = date.isAfter(_today);
                final hasOpportunities = summary.applicable > 0;
                final value = !isFuture && hasOpportunities
                    ? summary.successful / summary.applicable
                    : 0.0;
                final isMissed =
                    !isFuture &&
                    date.isBefore(_today) &&
                    hasOpportunities &&
                    summary.successful == 0;
                final arcColor = isMissed
                    ? AppColors.danger
                    : AppColors.primary;
                final status = isFuture
                    ? 'Upcoming'
                    : !hasOpportunities
                    ? 'No scheduled habits'
                    : '${summary.successful} of ${summary.applicable} completed';

                return Expanded(
                  child: Semantics(
                    label: '${weekdays[index]}: $status',
                    child: Tooltip(
                      message:
                          '${weekdays[index]} ${date.month}/${date.day}: $status',
                      child: Column(
                        children: [
                          SizedBox(
                            width: diameter,
                            height: diameter,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (!hasOpportunities || isFuture)
                                  Container(
                                    width: diameter,
                                    height: diameter,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.surfaceElevated,
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                  )
                                else
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: value),
                                    duration: const Duration(milliseconds: 350),
                                    builder: (context, animatedValue, _) =>
                                        CircularProgressIndicator(
                                          value: animatedValue,
                                          strokeWidth: 3.5,
                                          strokeCap: StrokeCap.round,
                                          backgroundColor:
                                              AppColors.surfaceElevated,
                                          color: arcColor,
                                        ),
                                  ),
                                if (hasOpportunities && !isFuture)
                                  Text(
                                    '${(value * 100).round()}%',
                                    style: TextStyle(
                                      color: arcColor,
                                      fontSize: diameter < 35 ? 8 : 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            weekdays[index],
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMonthlyActivityPage() {
    final monthStart = DateTime(_visibleMonth.year, _visibleMonth.month);
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final leadingDays = monthStart.weekday - DateTime.monday;
    final weekCount = (leadingDays + daysInMonth + 6) ~/ 7;
    final currentMonth = DateTime(_today.year, _today.month);
    final isCurrentMonth =
        _visibleMonth.year == currentMonth.year &&
        _visibleMonth.month == currentMonth.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Monthly Activity',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Previous month',
              onPressed: () => _changeActivityMonth(-1),
              icon: const Icon(Icons.chevron_left),
              color: AppColors.textSecondary,
              visualDensity: VisualDensity.compact,
            ),
            Text(
              _monthLabel(_visibleMonth),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: isCurrentMonth ? null : () => _changeActivityMonth(1),
              icon: const Icon(Icons.chevron_right),
              color: isCurrentMonth
                  ? AppColors.textMuted
                  : AppColors.textSecondary,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        Text(
          _getActivityStreakMessage(),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        ...List.generate(weekCount, (weekIndex) {
          return SizedBox(
            height: 20,
            child: Row(
              children: List.generate(7, (weekdayIndex) {
                final day = weekIndex * 7 + weekdayIndex - leadingDays + 1;
                if (day < 1 || day > daysInMonth) {
                  return const Expanded(child: SizedBox());
                }
                return Expanded(
                  child: Center(
                    child: _buildActivityDayCell(
                      DateTime(_visibleMonth.year, _visibleMonth.month, day),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
        const SizedBox(height: 5),
        _buildHeatmapLegend(),
      ],
    );
  }

  Widget _buildActivityDayCell(DateTime date) {
    final level = _getHeatLevel(date);
    final summary = _getDaySummary(date);
    final dateStatus = date.isAfter(_today)
        ? 'Upcoming'
        : summary.applicable == 0
        ? 'No scheduled activity'
        : '${summary.successful} of ${summary.applicable} successful';
    return Semantics(
      label: '${date.month}/${date.day}: $dateStatus',
      child: Tooltip(
        message: '${date.day}: $dateStatus',
        child: Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: _getHeatColor(level),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.border, width: 0.35),
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          'Less',
          style: TextStyle(color: AppColors.textMuted, fontSize: 9),
        ),
        const SizedBox(width: 5),
        for (var level = 0; level <= 5; level++) ...[
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _getHeatColor(level),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
        const SizedBox(width: 5),
        const Text(
          'More',
          style: TextStyle(color: AppColors.textMuted, fontSize: 9),
        ),
      ],
    );
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your habits',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${_todaysHabits.length} ${_todaysHabits.length == 1 ? 'habit' : 'habits'}',
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
