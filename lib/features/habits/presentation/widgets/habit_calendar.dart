import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/calendar_dates.dart';
import 'habit_day_status.dart';

class HabitCalendar extends StatelessWidget {
  static const _months = [
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

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final HabitDayStatus Function(DateTime date) statusForDate;
  final int? Function(DateTime date) countForDate;
  final String counterUnit;
  final bool isCounter;
  final Widget selectedDateDetails;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<int> onMonthChanged;

  const HabitCalendar({
    super.key,
    required this.visibleMonth,
    required this.selectedDate,
    required this.statusForDate,
    required this.countForDate,
    required this.counterUnit,
    required this.isCounter,
    required this.selectedDateDetails,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final month = DateTime(visibleMonth.year, visibleMonth.month);
    final daysInMonth = CalendarDates.daysInMonth(month);
    final leadingDays = CalendarDates.leadingDaysInMonth(month);
    final cellCount = CalendarDates.weeksInMonth(month) * 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Completion History',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => onMonthChanged(-1),
                icon: const Icon(Icons.chevron_left),
                color: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    CalendarDates.monthYearLabel(month),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () => onMonthChanged(1),
                icon: const Icon(Icons.chevron_right),
                color: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final day = index - leadingDays + 1;
              if (day < 1 || day > daysInMonth) return const SizedBox();

              return _buildDayCell(DateTime(month.year, month.month, day));
            },
          ),
          const SizedBox(height: 12),
          _buildLegend(),
          const SizedBox(height: 12),
          selectedDateDetails,
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final status = statusForDate(date);
    final count = isCounter ? countForDate(date) : null;
    final isSelected = DateUtils.isSameDay(date, selectedDate);
    final countLabel = count == null ? null : '$count';
    final label =
        '${_dateLabel(date)}: ${status.label}'
        '${count == null ? '' : ', $count $counterUnit'}';
    final color = _statusColor(status);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onDateSelected(date),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.surfaceElevated
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: status == HabitDayStatus.notScheduled
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 2),
                if (countLabel != null)
                  Text(
                    countLabel,
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontSize: 8,
                      height: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: status == HabitDayStatus.today
                          ? Colors.transparent
                          : color,
                      border: status == HabitDayStatus.today
                          ? Border.all(color: AppColors.textMuted)
                          : null,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        _buildLegendItem(HabitDayStatus.completed, AppColors.primary),
        _buildLegendItem(HabitDayStatus.missed, AppColors.danger),
        _buildLegendItem(HabitDayStatus.upcoming, AppColors.textMuted),
        _buildLegendItem(HabitDayStatus.notScheduled, AppColors.border),
      ],
    );
  }

  Widget _buildLegendItem(HabitDayStatus status, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          status.label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Color _statusColor(HabitDayStatus status) => switch (status) {
    HabitDayStatus.completed => AppColors.primary,
    HabitDayStatus.missed => AppColors.danger,
    HabitDayStatus.upcoming => AppColors.textMuted,
    HabitDayStatus.notScheduled || HabitDayStatus.today => AppColors.border,
  };

  String _dateLabel(DateTime date) =>
      '${_months[date.month - 1]} ${date.day}, ${date.year}';
}
