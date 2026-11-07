import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class TodayProgressCard extends StatelessWidget {
  final int completedHabits;
  final int scheduledHabits;

  const TodayProgressCard({
    super.key,
    required this.completedHabits,
    required this.scheduledHabits,
  });

  @override
  Widget build(BuildContext context) {
    final hasScheduledHabits = scheduledHabits > 0;
    final progress = hasScheduledHabits
        ? completedHabits / scheduledHabits
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
              '$completedHabits / $scheduledHabits Habits Completed',
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
          ] else
            const Text(
              'No habits scheduled for today',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
