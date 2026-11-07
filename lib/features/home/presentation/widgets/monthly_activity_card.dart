import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/calendar_dates.dart';
import 'home_progress_card.dart';

class MonthlyActivityCard extends StatelessWidget {
  final DateTime month;
  final DateTime today;
  final String streakMessage;
  final int Function(DateTime date) getActivityLevel;
  final String Function(DateTime date) getActivityDescription;
  final ValueChanged<int> onMonthChanged;

  const MonthlyActivityCard({
    super.key,
    required this.month,
    required this.today,
    required this.streakMessage,
    required this.getActivityLevel,
    required this.getActivityDescription,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(month.year, month.month);
    final weekCount = CalendarDates.weeksInMonth(monthStart);
    final currentMonth = DateTime(today.year, today.month);
    final isCurrentMonth = monthStart == currentMonth;

    return HomeProgressCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                onPressed: () => onMonthChanged(-1),
                icon: const Icon(Icons.chevron_left),
                color: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                _monthLabel(month),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: isCurrentMonth ? null : () => onMonthChanged(1),
                icon: const Icon(Icons.chevron_right),
                color: isCurrentMonth
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Text(
            streakMessage,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          _buildHeatmap(monthStart, weekCount),
          const SizedBox(height: 8),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeatmap(DateTime monthStart, int weekCount) {
    final leadingDays = CalendarDates.leadingDaysInMonth(monthStart);
    const cellSize = 15.0;
    const cellGap = 3.0;
    const heatmapWidth = (cellSize + cellGap) * 7;

    return Center(
      child: SizedBox(
        width: heatmapWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: CalendarDates.weekdayAbbreviations.map((day) {
                return SizedBox(
                  width: cellSize + cellGap,
                  child: Center(
                    child: Text(
                      day.substring(0, 1),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            ...List.generate(weekCount, (weekIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: cellGap),
                child: Row(
                  children: List.generate(7, (weekdayIndex) {
                    final day = weekIndex * 7 + weekdayIndex - leadingDays + 1;
                    if (day < 1 ||
                        day > CalendarDates.daysInMonth(monthStart)) {
                      return const SizedBox(
                        width: cellSize + cellGap,
                        height: cellSize,
                      );
                    }

                    final date = DateTime(month.year, month.month, day);
                    final level = getActivityLevel(date);
                    final description = getActivityDescription(date);
                    return Padding(
                      padding: const EdgeInsets.only(right: cellGap),
                      child: Tooltip(
                        message: '$day: $description',
                        child: Semantics(
                          label: '$day: $description',
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            decoration: BoxDecoration(
                              color: _heatColor(level),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.5),
                                width: 0.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
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
              color: _heatColor(level),
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

  Color _heatColor(int level) {
    switch (level) {
      case 0:
        return AppColors.surfaceElevated;
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

  String _monthLabel(DateTime date) {
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
    return '${months[date.month - 1]} ${date.year}';
  }
}
