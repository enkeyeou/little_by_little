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
  DateTime _selectedActivityDate = _dateOnly(DateTime.now());
  int _progressPage = 0;
  int _activityLoadGeneration = 0;
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

  DateTime _getActivityRangeStart(DateTime monthStart) {
    return _getWeekStart(monthStart);
  }

  DateTime _getActivityRangeEnd(DateTime monthEnd) {
    final end = _dateOnly(monthEnd);
    return end.add(Duration(days: DateTime.sunday - end.weekday));
  }

  Future<void> _refreshProgressData() async {
    final weekStart = _getWeekStart(_today);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final monthStart = DateTime(_visibleMonth.year, _visibleMonth.month);
    final monthEnd = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final generation = ++_activityLoadGeneration;

    final results = await Future.wait([
      _progressDataSource.getProgressBetweenDates(weekStart, weekEnd),
      _progressDataSource.getProgressBetweenDates(
        _getActivityRangeStart(monthStart),
        _getActivityRangeEnd(monthEnd),
      ),
    ]);

    if (!mounted || generation != _activityLoadGeneration) return;
    _applyLoadedProgress(results[0], results[1]);
  }

  Future<void> _loadActivityMonth() async {
    final monthStart = DateTime(_visibleMonth.year, _visibleMonth.month);
    final monthEnd = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final generation = ++_activityLoadGeneration;
    final progress = await _progressDataSource.getProgressBetweenDates(
      _getActivityRangeStart(monthStart),
      _getActivityRangeEnd(monthEnd),
    );

    if (!mounted || generation != _activityLoadGeneration) return;
    _applyLoadedProgress(null, progress);
  }

  void _applyLoadedProgress(
    List<HabitProgress>? weeklyProgress,
    List<HabitProgress> activityProgress,
  ) {
    final progressByDate = <DateTime, Map<String, HabitProgress>>{};
    for (final progress in activityProgress) {
      progressByDate.putIfAbsent(
        _dateOnly(progress.date),
        () => {},
      )[progress.habitId] = progress;
    }

    setState(() {
      if (weeklyProgress != null) {
        _todayProgress.clear();
        _weeklyCounts.clear();
        _weeklyTargetCounts.clear();

        for (final item in weeklyProgress) {
          final itemDate = _dateOnly(item.date);
          if (itemDate.isAfter(_today)) continue;
          if (itemDate == _today) {
            _todayProgress[item.habitId] = item;
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
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
      _selectedActivityDate =
          _visibleMonth.year == _today.year &&
              _visibleMonth.month == _today.month
          ? _today
          : DateTime(_visibleMonth.year, _visibleMonth.month);
    });
    _loadActivityMonth();
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
      final isSuccessful = _isDailyActivitySuccessful(
        habit,
        _getActivityProgress(habit, normalizedDate),
      );
      if (habit.scheduleType == HabitScheduleType.weeklyTarget &&
          !isSuccessful) {
        continue;
      }
      applicable++;
      if (isSuccessful) {
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

  ({int activeDays, int successfulSessions}) _getMonthlyActivitySummary() {
    final monthStart = DateTime(_visibleMonth.year, _visibleMonth.month);
    final monthEnd = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final effectiveEnd = monthEnd.isBefore(_today) ? monthEnd : _today;
    var activeDays = 0;
    var successfulSessions = 0;

    for (
      var date = monthStart;
      !date.isAfter(effectiveEnd);
      date = date.add(const Duration(days: 1))
    ) {
      final summary = _getDaySummary(date);
      if (summary.successful > 0) activeDays++;
      successfulSessions += summary.successful;
    }

    return (activeDays: activeDays, successfulSessions: successfulSessions);
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

  String _getActivityStatus(Habit habit, DateTime date) {
    final normalizedDate = _dateOnly(date);
    if (normalizedDate.isAfter(_today)) return 'Upcoming';
    final progress = _getActivityProgress(habit, normalizedDate);
    final isSuccessful = _isDailyActivitySuccessful(habit, progress);

    if (habit.scheduleType == HabitScheduleType.weeklyTarget) {
      if (isSuccessful) return 'Session recorded';
      return normalizedDate == _today ? 'In progress' : 'No session recorded';
    }

    if (habit.trackingType == TrackingType.counter &&
        habit.counterGoalPeriod == CounterGoalPeriod.weekly) {
      if ((progress?.count ?? 0) > 0) return 'Progress recorded';
      return normalizedDate == _today ? 'In progress' : 'No activity recorded';
    }

    if (isSuccessful) return 'Completed';
    return normalizedDate == _today ? 'In progress' : 'Not completed';
  }

  int _getWeeklyHabitCount(Habit habit, DateTime date) {
    final weekStart = _getWeekStart(date);
    var total = 0;
    for (var index = 0; index < 7; index++) {
      final day = weekStart.add(Duration(days: index));
      if (day.isAfter(_today) ||
          day.isBefore(_dateOnly(habit.createdAt)) ||
          !habit.isScheduledFor(day)) {
        continue;
      }
      total += _getActivityProgress(habit, day)?.count ?? 0;
    }
    return total;
  }

  int _getWeeklyHabitSessions(Habit habit, DateTime date) {
    final weekStart = _getWeekStart(date);
    var sessions = 0;
    for (var index = 0; index < 7; index++) {
      final day = weekStart.add(Duration(days: index));
      if (day.isAfter(_today) ||
          day.isBefore(_dateOnly(habit.createdAt)) ||
          !habit.isScheduledFor(day)) {
        continue;
      }
      if (_isSuccessfulSession(habit, _getActivityProgress(habit, day))) {
        sessions++;
      }
    }
    return sessions;
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
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: _progressPage == 0 ? 225 : 440,
              child: PageView(
                controller: _progressPageController,
                onPageChanged: (page) => setState(() => _progressPage = page),
                children: [
                  _buildTodayProgressPage(),
                  _buildMonthlyActivityPage(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProgressPageIndicator(0),
              const SizedBox(width: 8),
              _buildProgressPageIndicator(1),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _progressPage == 0
                ? 'Swipe to view monthly activity'
                : 'Swipe to view today’s progress',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPageIndicator(int page) {
    final isSelected = _progressPage == page;
    return Semantics(
      button: true,
      label: page == 0 ? "Today's progress" : 'Monthly activity',
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
    final scheduledHabits = _todaysHabits;
    final successful = _getTodaySuccessfulHabits();
    final dailyOpportunities = _getDaySummary(_today).applicable;
    final hasScheduledHabits = dailyOpportunities > 0;
    final progress = hasScheduledHabits ? successful / dailyOpportunities : 0.0;
    final activityCount = scheduledHabits
        .where(
          (habit) =>
              _todayProgress[habit.id]?.isCompleted == true ||
              (_todayProgress[habit.id]?.count ?? 0) > 0,
        )
        .length;

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
            '$successful / $dailyOpportunities habits/sessions completed',
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
          const SizedBox(height: 10),
          Text(
            successful == dailyOpportunities
                ? "All of today's due goals are complete."
                : '$activityCount ${activityCount == 1 ? 'habit has' : 'habits have'} activity recorded today.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ] else ...[
          const SizedBox(height: 22),
          Text(
            scheduledHabits.isEmpty
                ? 'No habits scheduled for today'
                : 'No daily goals due today',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            scheduledHabits.any(
                  (habit) =>
                      habit.scheduleType == HabitScheduleType.weeklyTarget,
                )
                ? 'Weekly targets remain available whenever you record a session.'
                : 'Enjoy the space or take a small step whenever you like.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
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
    final cellCount = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
    final monthlySummary = _getMonthlyActivitySummary();

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
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
                onPressed: () => _changeActivityMonth(1),
                icon: const Icon(Icons.chevron_right),
                color: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Text(
            '${monthlySummary.activeDays} active days · ${monthlySummary.successfulSessions} successful completions/sessions',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 5),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final day = index - leadingDays + 1;
              if (day < 1 || day > daysInMonth) return const SizedBox();
              return _buildActivityDayCell(
                DateTime(_visibleMonth.year, _visibleMonth.month, day),
              );
            },
          ),
          const SizedBox(height: 9),
          _buildHeatmapLegend(),
          const SizedBox(height: 10),
          _buildSelectedActivityDetails(),
        ],
      ),
    );
  }

  Widget _buildActivityDayCell(DateTime date) {
    final level = _getHeatLevel(date);
    final selected = _dateOnly(date) == _selectedActivityDate;
    final summary = _getDaySummary(date);
    final dateStatus = date.isAfter(_today)
        ? 'Upcoming'
        : summary.applicable == 0
        ? 'No scheduled activity'
        : '${summary.successful} of ${summary.applicable} successful';
    return Semantics(
      button: true,
      selected: selected,
      label: '${_dateLabel(date)}: $dateStatus',
      child: Tooltip(
        message: '${date.day}: $dateStatus',
        child: InkWell(
          onTap: () => setState(() => _selectedActivityDate = _dateOnly(date)),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              color: _getHeatColor(level),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: selected ? AppColors.textPrimary : AppColors.border,
                width: selected ? 1.5 : 0.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: date.isAfter(_today)
                    ? AppColors.textMuted
                    : AppColors.textPrimary,
                fontSize: 9,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
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
        for (var level = -1; level <= 5; level++) ...[
          Container(
            width: 10,
            height: 10,
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

  Widget _buildSelectedActivityDetails() {
    final date = _selectedActivityDate;
    final isFuture = date.isAfter(_today);
    final applicableHabits = isFuture ? <Habit>[] : _getApplicableHabits(date);
    final summary = _getDaySummary(date);
    final percentage = summary.applicable == 0
        ? null
        : (summary.successful / summary.applicable * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dateLabel(date),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFuture
                ? 'Upcoming date — no activity recorded yet.'
                : summary.applicable == 0
                ? 'No habits scheduled for this date.'
                : '${summary.successful} of ${summary.applicable} habits/sessions successful${percentage == null ? '' : ' — $percentage%'}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          if (applicableHabits.isNotEmpty) ...[
            const SizedBox(height: 7),
            ...applicableHabits.map((habit) {
              final progress = _getActivityProgress(habit, date);
              final status = _getActivityStatus(habit, date);
              final weeklyTarget =
                  habit.scheduleType == HabitScheduleType.weeklyTarget;
              final weeklyCounter =
                  habit.trackingType == TrackingType.counter &&
                  habit.counterGoalPeriod == CounterGoalPeriod.weekly;
              final dailyCounter =
                  habit.trackingType == TrackingType.counter &&
                  habit.counterGoalPeriod == CounterGoalPeriod.daily;
              final weeklyCount = weeklyCounter
                  ? _getWeeklyHabitCount(habit, date)
                  : null;
              final weeklySessions = weeklyTarget
                  ? _getWeeklyHabitSessions(habit, date)
                  : null;
              final subtitle = habit.trackingType != TrackingType.counter
                  ? status
                  : '${_getActivityCount(progress)} ${habit.counterUnit} · $status';

              return Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                            ),
                          ),
                          if (weeklyTarget)
                            Text(
                              '$weeklySessions / ${habit.weeklyTarget} sessions this week',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                              ),
                            ),
                          if (weeklyCounter && habit.counterGoal != null)
                            Text(
                              'This week: $weeklyCount / ${habit.counterGoal} ${habit.counterUnit}${weeklyCount! >= habit.counterGoal! ? ' — goal met' : ''}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                              ),
                            ),
                          if (dailyCounter && habit.counterGoal != null)
                            Text(
                              'Daily goal: ${habit.counterGoal} ${habit.counterUnit}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  int _getActivityCount(HabitProgress? progress) => progress?.count ?? 0;

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
