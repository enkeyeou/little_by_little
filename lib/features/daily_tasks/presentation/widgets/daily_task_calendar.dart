import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/calendar_dates.dart';
import '../../domain/models/daily_task.dart';

class DailyTaskCalendar extends StatefulWidget {
  final List<DailyTask> allTasks;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const DailyTaskCalendar({
    super.key,
    required this.allTasks,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<DailyTaskCalendar> createState() => _DailyTaskCalendarState();
}

class _DailyTaskCalendarState extends State<DailyTaskCalendar> {
  bool _isExpanded = false;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  @override
  void didUpdateWidget(covariant DailyTaskCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate.year != widget.selectedDate.year ||
        oldWidget.selectedDate.month != widget.selectedDate.month) {
      _visibleMonth = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
      );
    }
  }

  void _toggleCalendar() {
    setState(() => _isExpanded = !_isExpanded);
  }

  void _changePeriod(int direction) {
    if (_isExpanded) {
      setState(() {
        _visibleMonth = DateTime(
          _visibleMonth.year,
          _visibleMonth.month + direction,
        );
      });
      return;
    }

    widget.onDateChanged(
      widget.selectedDate.add(Duration(days: direction * 7)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = CalendarDates.startOfWeek(widget.selectedDate);

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
                        _monthLabel(_visibleMonth),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isExpanded
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
                onPressed: () => _changePeriod(-1),
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _changePeriod(1),
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
            child: _isExpanded
                ? Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: CalendarDates.weekdayAbbreviations.map((day) {
                          return Expanded(
                            child: Center(
                              child: Text(
                                day.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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
          final hasTasks = _hasIncompleteTasks(date);

          return Expanded(
            child: InkWell(
              onTap: () => widget.onDateChanged(date),
              child: Column(
                children: [
                  Text(
                    CalendarDates.weekdayAbbreviations[index].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDayNumber(date, isSelected),
                  const SizedBox(height: 6),
                  _buildTaskIndicator(hasTasks),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMonthGrid() {
    final daysInMonth = CalendarDates.daysInMonth(_visibleMonth);
    final leadingDays = CalendarDates.leadingDaysInMonth(_visibleMonth);
    final totalCells = CalendarDates.weeksInMonth(_visibleMonth) * 7;

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
          final day = index - leadingDays + 1;
          if (day < 1 || day > daysInMonth) {
            return const SizedBox.shrink();
          }

          final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
          final isSelected = DateUtils.isSameDay(date, widget.selectedDate);

          return InkWell(
            onTap: () => widget.onDateChanged(date),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildDayNumber(date, isSelected),
                const SizedBox(height: 6),
                _buildTaskIndicator(_hasIncompleteTasks(date)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayNumber(DateTime date, bool isSelected) {
    return Container(
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
          color: isSelected ? AppColors.background : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTaskIndicator(bool hasTasks) {
    return SizedBox(
      width: 5,
      height: 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: hasTasks ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  bool _hasIncompleteTasks(DateTime date) => widget.allTasks.any(
    (task) => DateUtils.isSameDay(task.date, date) && !task.isCompleted,
  );

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
}
