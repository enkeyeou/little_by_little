import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/daily_task.dart';

class DailyTaskList extends StatelessWidget {
  final List<DailyTask> tasks;
  final ValueChanged<DailyTask> onTaskUpdated;
  final ValueChanged<DailyTask> onTaskTapped;

  const DailyTaskList({
    super.key,
    required this.tasks,
    required this.onTaskUpdated,
    required this.onTaskTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const _DailyTaskEmptyState();

    final activeTasks = tasks.where((task) => !task.isCompleted).toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return a.createdAt.compareTo(b.createdAt);
      });
    final completedTasks = tasks.where((task) => task.isCompleted).toList();

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
          const _AllTasksCompletedCard(),
          const SizedBox(height: 28),
        ],
        ...activeTasks.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DailyTaskCard(
              task: task,
              onTaskUpdated: onTaskUpdated,
              onTaskTapped: onTaskTapped,
            ),
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
                      child: _DailyTaskCard(
                        task: task,
                        onTaskUpdated: onTaskUpdated,
                        onTaskTapped: onTaskTapped,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _DailyTaskEmptyState extends StatelessWidget {
  const _DailyTaskEmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
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
      ),
    );
  }
}

class _AllTasksCompletedCard extends StatelessWidget {
  const _AllTasksCompletedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 42),
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
            'Take a breath and give yourself credit for showing up.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyTaskCard extends StatelessWidget {
  final DailyTask task;
  final ValueChanged<DailyTask> onTaskUpdated;
  final ValueChanged<DailyTask> onTaskTapped;

  const _DailyTaskCard({
    required this.task,
    required this.onTaskUpdated,
    required this.onTaskTapped,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTaskTapped(task),
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
              onPressed: () =>
                  onTaskUpdated(task.copyWith(isCompleted: !task.isCompleted)),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
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
                onPressed: () =>
                    onTaskUpdated(task.copyWith(isPinned: !task.isPinned)),
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
