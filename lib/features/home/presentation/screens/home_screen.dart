import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../habits/domain/models/habit.dart';
import '../../../habits/data/datasources/habit_progress_local_data_source.dart';
import '../../../habits/domain/models/habit_progress.dart';

class HomeScreen extends StatefulWidget {
  final List<Habit> habits;

  const HomeScreen({super.key, required this.habits});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HabitProgressLocalDataSource _progressDataSource =
      HabitProgressLocalDataSource();

  final Map<String, HabitProgress> _todayProgress = {};
  final Map<String, int> _weeklyCounts = {};

  @override
  void initState() {
    super.initState();
    _loadTodayProgress();
  }

  Future<void> _loadTodayProgress() async {
    final today = DateTime.now();

    final todayProgress = await _progressDataSource.getProgressForDate(today);

    final weekStart = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );

    final weekEnd = weekStart.add(const Duration(days: 6));

    final weeklyProgress = await _progressDataSource.getProgressBetweenDates(
      weekStart,
      weekEnd,
    );

    if (!mounted) return;

    setState(() {
      _todayProgress.clear();
      _weeklyCounts.clear();

      for (final item in todayProgress) {
        _todayProgress[item.habitId] = item;
      }

      for (final item in weeklyProgress) {
        _weeklyCounts.update(
          item.habitId,
          (count) => count + item.count,
          ifAbsent: () => item.count,
        );
      }
    });
  }

  bool _isCompleted(String habitId) {
    return _todayProgress[habitId]?.isCompleted ?? false;
  }

  int get _totalHabits => widget.habits
      .where((habit) => habit.trackingType == TrackingType.completion)
      .length;

  int get _completedHabits => widget.habits
      .where(
        (habit) =>
            habit.trackingType == TrackingType.completion &&
            _isCompleted(habit.id),
      )
      .length;

  double get _dailyProgress =>
      _totalHabits == 0 ? 0 : _completedHabits / _totalHabits;

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

    setState(() {
      _todayProgress[habit.id] = progress;
    });
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

    setState(() {
      _todayProgress[habit.id] = progress;
      _weeklyCounts[habit.id] = weeklyCount;
    });
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

            // Daily Progress Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's progress",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(_dailyProgress * 100).round()}%',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    '$_completedHabits / $_totalHabits',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: _dailyProgress,
                      minHeight: 7,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Every little effort adds up.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
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
                  '${widget.habits.length} ${widget.habits.length == 1 ? 'habit' : 'habits'}',
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
            if (widget.habits.isEmpty)
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
              ...widget.habits.map((habit) {
                return Container(
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
                          '${_getTodayCount(habit.id)}',
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
                );
              }),
          ],
        ),
      ),
    );
  }
}
