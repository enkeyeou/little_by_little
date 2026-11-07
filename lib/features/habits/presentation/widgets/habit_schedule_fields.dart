import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class HabitScheduleFields extends StatelessWidget {
  final String scheduleType;
  final Set<int> selectedWeekdays;
  final int everyNDays;
  final int weeklyTarget;
  final bool showScheduleError;
  final ValueChanged<String> onScheduleTypeChanged;
  final ValueChanged<int> onWeekdayToggled;
  final ValueChanged<int> onEveryNDaysChanged;
  final ValueChanged<int> onWeeklyTargetChanged;

  const HabitScheduleFields({
    super.key,
    required this.scheduleType,
    required this.selectedWeekdays,
    required this.everyNDays,
    required this.weeklyTarget,
    required this.showScheduleError,
    required this.onScheduleTypeChanged,
    required this.onWeekdayToggled,
    required this.onEveryNDaysChanged,
    required this.onWeeklyTargetChanged,
  });

  static const _scheduleTypes = [
    'Every day',
    'Selected days',
    'Every N days',
    'Weekly target',
  ];

  static const _weekdayLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];
  static const _weekdayValues = [
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'When do you want to do this habit?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _scheduleTypes.map((schedule) {
            return ChoiceChip(
              label: Text(schedule),
              selected: scheduleType == schedule,
              onSelected: (_) => onScheduleTypeChanged(schedule),
            );
          }).toList(),
        ),
        if (scheduleType == 'Selected days') ...[
          const SizedBox(height: 20),
          const Text(
            'Choose your days',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_weekdayLabels.length, (index) {
              final weekday = _weekdayValues[index];
              return FilterChip(
                label: Text(_weekdayLabels[index]),
                selected: selectedWeekdays.contains(weekday),
                onSelected: (_) => onWeekdayToggled(weekday),
              );
            }),
          ),
          if (showScheduleError && selectedWeekdays.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Please select at least one day.',
              style: TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ],
        ],
        if (scheduleType == 'Every N days') ...[
          const SizedBox(height: 20),
          const Text(
            'Repeat every',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: everyNDays > 2
                    ? () => onEveryNDaysChanged(everyNDays - 1)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Text(
                '$everyNDays days',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: everyNDays < 30
                    ? () => onEveryNDaysChanged(everyNDays + 1)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          Text(
            'Choose a repeat interval from 2 to 30 days.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
        if (scheduleType == 'Weekly target') ...[
          const SizedBox(height: 20),
          const Text(
            'How many times per week?',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: weeklyTarget > 1
                    ? () => onWeeklyTargetChanged(weeklyTarget - 1)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Text(
                '$weeklyTarget times per week',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: weeklyTarget < 7
                    ? () => onWeeklyTargetChanged(weeklyTarget + 1)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          Text(
            'Complete this habit at least this many times each week.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
