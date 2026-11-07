import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/calendar_dates.dart';
import 'habit_day_status.dart';

class HabitWeekProgress extends StatelessWidget {
  final DateTime weekStart;
  final DateTime today;
  final HabitDayStatus Function(DateTime date) statusForDate;
  final int? Function(DateTime date) countForDate;
  final String counterUnit;
  final bool isCounter;

  const HabitWeekProgress({
    super.key,
    required this.weekStart,
    required this.today,
    required this.statusForDate,
    required this.countForDate,
    required this.counterUnit,
    required this.isCounter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));
        final status = statusForDate(date);
        final count = isCounter ? countForDate(date) : null;
        final weekday = CalendarDates.weekdayAbbreviations[index];
        final label =
            '$weekday ${date.month}/${date.day}: ${status.label}'
            '${count == null ? '' : ', $count $counterUnit'}';

        return Expanded(
          child: Semantics(
            label: label,
            child: Tooltip(
              message: label,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weekday,
                    style: TextStyle(
                      color: DateUtils.isSameDay(date, today)
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: DateUtils.isSameDay(date, today)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildIndicator(status, count),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildIndicator(HabitDayStatus status, int? count) {
    final isCompleted = status == HabitDayStatus.completed;
    final color = switch (status) {
      HabitDayStatus.completed => AppColors.primary,
      HabitDayStatus.missed => AppColors.danger,
      HabitDayStatus.upcoming => AppColors.textMuted,
      HabitDayStatus.notScheduled || HabitDayStatus.today => AppColors.border,
    };

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.primary
            : color.withValues(
                alpha: status == HabitDayStatus.notScheduled ? 0.3 : 0.16,
              ),
        shape: BoxShape.circle,
        border: isCompleted
            ? null
            : Border.all(color: color.withValues(alpha: 0.75)),
      ),
      alignment: Alignment.center,
      child: switch (status) {
        HabitDayStatus.completed => const Icon(
          Icons.check_rounded,
          size: 20,
          color: AppColors.background,
        ),
        HabitDayStatus.missed => Icon(
          Icons.close_rounded,
          size: 16,
          color: color,
        ),
        HabitDayStatus.upcoming => Icon(
          Icons.circle_outlined,
          size: 13,
          color: color,
        ),
        HabitDayStatus.notScheduled || HabitDayStatus.today =>
          isCounter && count != null
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
      },
    );
  }
}
