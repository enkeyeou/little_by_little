import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/daily_task.dart';

class DailyTasksScreen extends StatefulWidget {
  final List<DailyTask> tasks;
  final List<DailyTask> allTasks;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<DailyTask> onTaskUpdated;
  final ValueChanged<DailyTask> onTaskTapped;

  const DailyTasksScreen({
    super.key,
    required this.tasks,
    required this.allTasks,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onTaskUpdated,
    required this.onTaskTapped,
  });

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  bool _isCalendarExpanded = false;
  late DateTime _visibleMonth;
  final ScrollController _taskScrollController = ScrollController();

  void _toggleCalendar() {
    setState(() {
      _isCalendarExpanded = !_isCalendarExpanded;
    });
  }

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  @override
  void dispose() {
    _taskScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DailyTasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedDate.year != widget.selectedDate.year ||
        oldWidget.selectedDate.month != widget.selectedDate.month) {
      _visibleMonth = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          controller: _taskScrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Tasks',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'One step at a time. One task at a time.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildDateSelector(context),
              const SizedBox(height: 24),
              if (widget.tasks.isEmpty)
                SizedBox(height: 300, child: _buildEmptyState())
              else
                _buildTaskList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final weekStart = widget.selectedDate.subtract(
      Duration(days: widget.selectedDate.weekday % 7),
    );

    final monthLabel =
        '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
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
                        monthLabel,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isCalendarExpanded
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
                onPressed: () {
                  if (_isCalendarExpanded) {
                    setState(() {
                      _visibleMonth = DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month - 1,
                      );
                    });
                  } else {
                    widget.onDateChanged(
                      widget.selectedDate.subtract(const Duration(days: 7)),
                    );
                  }
                },
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () {
                  if (_isCalendarExpanded) {
                    setState(() {
                      _visibleMonth = DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month + 1,
                      );
                    });
                  } else {
                    widget.onDateChanged(
                      widget.selectedDate.add(const Duration(days: 7)),
                    );
                  }
                },
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
            child: _isCalendarExpanded
                ? Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: List.generate(7, (index) {
                          return Expanded(
                            child: Center(
                              child: Text(
                                _weekdayName(index == 0 ? 7 : index),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      _buildMonthGrid(),
                    ],
                  )
                : _buildWeekView(weekStart),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(DateTime weekStart) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, widget.selectedDate);
          final hasTasks = widget.allTasks.any(
            (task) => DateUtils.isSameDay(task.date, date) && !task.isCompleted,
          );

          return Expanded(
            child: GestureDetector(
              onTapDown: (_) => widget.onDateChanged(date),
              child: Column(
                children: [
                  Text(
                    _weekdayName(date.weekday),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.background
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 5,
                    height: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: hasTasks
                            ? AppColors.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMonthGrid() {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);

    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;

    final startingOffset = firstDay.weekday % 7;
    final totalCells = ((startingOffset + daysInMonth + 6) ~/ 7) * 7;

    return SizedBox(
      height: (totalCells ~/ 7) * 54.0,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: totalCells,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 0,
          mainAxisExtent: 50,
        ),
        itemBuilder: (context, index) {
          final day = index - startingOffset + 1;

          if (day < 1 || day > daysInMonth) {
            return const SizedBox.shrink();
          }

          final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);

          final isSelected = DateUtils.isSameDay(date, widget.selectedDate);

          final hasTasks = widget.allTasks.any(
            (task) => DateUtils.isSameDay(task.date, date) && !task.isCompleted,
          );

          return GestureDetector(
            onTapDown: (_) {
              widget.onDateChanged(date);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.background
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 5,
                  height: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: hasTasks ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _weekdayName(int weekday) {
    const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return days[weekday % 7];
  }

  String _monthName(int month) {
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
    return months[month - 1];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.checklist_rounded,
            color: AppColors.primary,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nothing on your list yet.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a small task and get started.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context) {
    final activeTasks = widget.tasks
        .where((task) => !task.isCompleted)
        .toList();
    final completedTasks = widget.tasks
        .where((task) => task.isCompleted)
        .toList();

    activeTasks.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }

      return a.createdAt.compareTo(b.createdAt);
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activeTasks.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your tasks',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${activeTasks.length} remaining',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (activeTasks.isEmpty) ...[
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 42,
                ),
                SizedBox(height: 16),
                Text(
                  'One day, one step at a time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "You've completed everything on your list for today. "
                  "Take a breath and give yourself credit for showing up.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],

        ...activeTasks.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTaskCard(task),
          ),
        ),

        if (completedTasks.isNotEmpty) ...[
          const SizedBox(height: 12),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              childrenPadding: const EdgeInsets.only(top: 8),
              leading: const Icon(
                Icons.check_circle_outline,
                color: AppColors.primary,
                size: 21,
              ),
              title: const Text(
                'Completed',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${completedTasks.length} ${completedTasks.length == 1 ? 'task' : 'tasks'} completed',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              iconColor: AppColors.textSecondary,
              collapsedIconColor: AppColors.textSecondary,
              children: completedTasks
                  .map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTaskCard(task),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTaskCard(DailyTask task) {
    return InkWell(
      onTap: () => widget.onTaskTapped(task),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                widget.onTaskUpdated(
                  task.copyWith(isCompleted: !task.isCompleted),
                );
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  key: ValueKey(task.isCompleted),
                  color: task.isCompleted
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      color: task.isCompleted
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    child: Text(task.title),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!task.isCompleted)
              IconButton(
                onPressed: () {
                  widget.onTaskUpdated(task.copyWith(isPinned: !task.isPinned));
                },
                icon: Icon(
                  task.isPinned
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: task.isPinned
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                tooltip: task.isPinned ? 'Unpin task' : 'Pin task',
              ),
          ],
        ),
      ),
    );
  }
}
