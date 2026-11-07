import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/calendar_dates.dart';
import 'home_progress_card.dart';

typedef DailyProgressSummary = ({int applicable, int successful});

class WeeklyProgressCard extends StatelessWidget {
  final DateTime weekStart;
  final DateTime today;
  final DailyProgressSummary Function(DateTime date) getDaySummary;

  const WeeklyProgressCard({
    super.key,
    required this.weekStart,
    required this.today,
    required this.getDaySummary,
  });

  @override
  Widget build(BuildContext context) {
    return HomeProgressCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 3),
          Text(
            CalendarDates.weekRangeLabel(weekStart),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth / 7;
              final diameter = (cellWidth - 8).clamp(25.0, 36.0);
              return Row(
                children: List.generate(7, (index) {
                  final date = weekStart.add(Duration(days: index));
                  final summary = getDaySummary(date);
                  final isUpcoming = CalendarDates.dateOnly(
                    date,
                  ).isAfter(CalendarDates.dateOnly(today));
                  final hasApplicableHabits = summary.applicable > 0;
                  final progress = hasApplicableHabits && !isUpcoming
                      ? summary.successful / summary.applicable
                      : 0.0;
                  final weekday = CalendarDates.weekdayAbbreviations[index];
                  final status = isUpcoming
                      ? 'Upcoming'
                      : hasApplicableHabits
                      ? '${(progress * 100).round()}% completed'
                      : 'No scheduled habits';

                  return Expanded(
                    child: Semantics(
                      label: '$weekday ${date.month}/${date.day}: $status',
                      child: Tooltip(
                        message: '$weekday ${date.month}/${date.day}: $status',
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              weekday,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: diameter,
                              height: diameter,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (hasApplicableHabits && !isUpcoming)
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: progress),
                                      duration: const Duration(
                                        milliseconds: 350,
                                      ),
                                      builder: (context, value, _) =>
                                          CircularProgressIndicator(
                                            value: value,
                                            strokeWidth: 4.5,
                                            strokeCap: StrokeCap.round,
                                            backgroundColor: AppColors.border,
                                            color: AppColors.warning,
                                          ),
                                    )
                                  else
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.border,
                                          width: 4,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
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
      ),
    );
  }
}
