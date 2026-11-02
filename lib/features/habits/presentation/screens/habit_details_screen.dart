import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/habit.dart';
import 'add_habit_screen.dart';

class HabitDetailsScreen extends StatelessWidget {
  final Habit habit;
  final Future<bool> Function(String id)? onHabitDeleted;

  const HabitDetailsScreen({
    super.key,
    required this.habit,
    this.onHabitDeleted,
  });

  String _getScheduleDescription() {
    switch (habit.scheduleType) {
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

        return habit.selectedWeekdays.map((day) => days[day - 1]).join(', ');

      case HabitScheduleType.everyNDays:
        return 'Every ${habit.everyNDays} days';

      case HabitScheduleType.weeklyTarget:
        return '${habit.weeklyTarget} times per week';
    }
  }

  String _getTrackingDescription() {
    return habit.trackingType == TrackingType.completion
        ? 'Completion-based'
        : 'Counter-based';
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
                  builder: (context) => AddHabitScreen(habit: habit),
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
                    'Are you sure you want to delete "${habit.name}"? '
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

              final deleted = await onHabitDeleted?.call(habit.id) ?? false;

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
                  color: habit.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(habit.emoji, style: const TextStyle(fontSize: 42)),
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                habit.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (habit.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Center(
                child: Text(
                  habit.description,
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

            if (habit.trackingType == TrackingType.counter) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.flag_outlined,
                title: 'Counter goal',
                value: habit.counterGoal == null
                    ? 'No goal set'
                    : '${habit.counterGoal} ${habit.counterUnit} '
                          '${habit.counterGoalPeriod.name}',
              ),
            ],

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.event_outlined,
              title: 'Created on',
              value:
                  '${habit.createdAt.month}/${habit.createdAt.day}/${habit.createdAt.year}',
            ),
          ],
        ),
      ),
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
