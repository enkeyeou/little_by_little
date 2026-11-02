import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/models/habit.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedEmoji = '🌱';
  Color _selectedColor = AppColors.primary;
  String _trackingType = 'Completion';
  String _counterGoal = '';
  String _counterUnit = 'times';
  String _counterGoalPeriod = 'Daily';
  String _scheduleType = 'Every day';
  bool _showNameError = false;
  bool _showCounterGoalError = false;
  bool _showScheduleError = false;
  bool _showCounterUnitError = false;

  final Set<int> _selectedWeekdays = {};

  int _everyNDays = 2;

  int _weeklyTarget = 3;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Habit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Build a better routine,',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'one little step at a time.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 28),

            // Habit Name
            const Text(
              'Habit name',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              onChanged: (value) {
                if (_showNameError && value.trim().isNotEmpty) {
                  setState(() {
                    _showNameError = false;
                  });
                }
              },
              decoration: InputDecoration(
                hintText: 'e.g. Read for 15 minutes',
                errorText: _showNameError ? 'Please enter a habit name.' : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Description
            const Text(
              'Description (optional)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Why is this habit important to you?',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Habit Icon
            const Text(
              'Choose an icon',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ['🌱', '📚', '💧', '🏃', '🧘', '💪', '🎨', '💤'].map((
                emoji,
              ) {
                final isSelected = _selectedEmoji == emoji;

                return ChoiceChip(
                  label: Text(emoji, style: const TextStyle(fontSize: 20)),
                  selected: isSelected,
                  showCheckmark: false,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedEmoji = emoji;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Habit Color
            const Text(
              'Choose a color',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 14,
              runSpacing: 14,
              children:
                  [
                    const Color(0xFF80CFA0),
                    const Color(0xFF80B8CF),
                    const Color(0xFF9B91D4),
                    const Color(0xFFE5A0B5),
                    const Color(0xFFE8BE78),
                    const Color(0xFFDA9178),
                    const Color(0xFF9BA7B8),
                  ].map((color) {
                    final isSelected = _selectedColor == color;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.textPrimary,
                                  width: 3,
                                )
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: AppColors.background,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 24),

            // Tracking Type
            const Text(
              'How do you want to track this habit?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Completion'),
                  selected: _trackingType == 'Completion',
                  onSelected: (_) {
                    setState(() {
                      _trackingType = 'Completion';
                    });
                  },
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.numbers, size: 18),
                  label: const Text('Counter'),
                  selected: _trackingType == 'Counter',
                  onSelected: (_) {
                    setState(() {
                      _trackingType = 'Counter';
                    });
                  },
                ),
              ],
            ),
            // Counter Configuration
            if (_trackingType == 'Counter') ...[
              const SizedBox(height: 24),

              const Text(
                'Set your target',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _counterGoal = value;

                  final goal = int.tryParse(value);

                  if (_showCounterGoalError &&
                      (value.trim().isEmpty || (goal != null && goal > 0))) {
                    setState(() {
                      _showCounterGoalError = false;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'e.g. 8',
                  errorText: _showCounterGoalError
                      ? 'Enter a valid amount greater than zero.'
                      : null,
                  labelText: 'Target amount',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                onChanged: (value) {
                  _counterUnit = value;

                  if (_showCounterUnitError && value.trim().isNotEmpty) {
                    setState(() {
                      _showCounterUnitError = false;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'e.g. glasses, pages, minutes',
                  labelText: 'Unit',
                  errorText: _showCounterUnitError
                      ? 'Please enter a unit.'
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Goal frequency',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                children: ['Daily', 'Weekly'].map((period) {
                  return ChoiceChip(
                    label: Text(period),
                    selected: _counterGoalPeriod == period,
                    onSelected: (_) {
                      setState(() {
                        _counterGoalPeriod = period;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 28),

            // Habit Schedule
            const Text(
              'When do you want to do this habit?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  [
                    'Every day',
                    'Selected days',
                    'Every N days',
                    'Weekly target',
                  ].map((schedule) {
                    return ChoiceChip(
                      label: Text(schedule),
                      selected: _scheduleType == schedule,
                      onSelected: (_) {
                        setState(() {
                          _scheduleType = schedule;
                        });
                      },
                    );
                  }).toList(),
            ),
            if (_scheduleType == 'Selected days') ...[
              const SizedBox(height: 20),

              const Text(
                'Choose your days',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  final dayNumber = index + 1;
                  const dayLabels = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];

                  final isSelected = _selectedWeekdays.contains(dayNumber);

                  return FilterChip(
                    label: Text(dayLabels[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedWeekdays.add(dayNumber);
                        } else {
                          _selectedWeekdays.remove(dayNumber);
                        }

                        if (_selectedWeekdays.isNotEmpty) {
                          _showScheduleError = false;
                        }
                      });
                    },
                  );
                }),
              ),
              if (_showScheduleError && _selectedWeekdays.isEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Please select at least one day.',
                  style: TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ],
            ],
            if (_scheduleType == 'Every N days') ...[
              const SizedBox(height: 20),

              const Text(
                'Repeat every',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  IconButton(
                    onPressed: _everyNDays > 2
                        ? () {
                            setState(() {
                              _everyNDays--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove),
                  ),

                  Text(
                    '$_everyNDays days',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  IconButton(
                    onPressed: _everyNDays < 30
                        ? () {
                            setState(() {
                              _everyNDays++;
                            });
                          }
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
            if (_scheduleType == 'Weekly target') ...[
              const SizedBox(height: 20),

              const Text(
                'How many times per week?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  IconButton(
                    onPressed: _weeklyTarget > 1
                        ? () {
                            setState(() {
                              _weeklyTarget--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove),
                  ),

                  Text(
                    '$_weeklyTarget times per week',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  IconButton(
                    onPressed: _weeklyTarget < 7
                        ? () {
                            setState(() {
                              _weeklyTarget++;
                            });
                          }
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
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final scheduleIsInvalid =
                      _scheduleType == 'Selected days' &&
                      _selectedWeekdays.isEmpty;
                  final nameIsEmpty = _nameController.text.trim().isEmpty;

                  final goal = int.tryParse(_counterGoal.trim());

                  final counterGoalIsInvalid =
                      _trackingType == 'Counter' &&
                      _counterGoal.trim().isNotEmpty &&
                      (goal == null || goal <= 0);

                  final counterUnitIsInvalid =
                      _trackingType == 'Counter' &&
                      _counterGoal.trim().isNotEmpty &&
                      _counterUnit.trim().isEmpty;

                  setState(() {
                    _showNameError = nameIsEmpty;
                    _showCounterGoalError = counterGoalIsInvalid;
                    _showScheduleError = scheduleIsInvalid;
                    _showCounterUnitError = counterUnitIsInvalid;
                  });

                  if (nameIsEmpty ||
                      counterGoalIsInvalid ||
                      scheduleIsInvalid ||
                      counterUnitIsInvalid) {
                    return;
                  }

                  final habit = Habit(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: _nameController.text.trim(),
                    description: _descriptionController.text.trim(),
                    emoji: _selectedEmoji,
                    color: _selectedColor,

                    trackingType: _trackingType == 'Counter'
                        ? TrackingType.counter
                        : TrackingType.completion,

                    counterGoal:
                        _trackingType == 'Counter' &&
                            _counterGoal.trim().isNotEmpty
                        ? int.parse(_counterGoal.trim())
                        : null,

                    counterUnit: _counterUnit.trim().isEmpty
                        ? 'times'
                        : _counterUnit.trim(),

                    counterGoalPeriod: _counterGoalPeriod == 'Weekly'
                        ? CounterGoalPeriod.weekly
                        : CounterGoalPeriod.daily,

                    scheduleType: switch (_scheduleType) {
                      'Selected days' => HabitScheduleType.selectedDays,
                      'Every N days' => HabitScheduleType.everyNDays,
                      'Weekly target' => HabitScheduleType.weeklyTarget,
                      _ => HabitScheduleType.everyDay,
                    },

                    selectedWeekdays: Set<int>.unmodifiable(_selectedWeekdays),
                    everyNDays: _everyNDays,
                    weeklyTarget: _weeklyTarget,
                    createdAt: DateTime.now(),
                  );

                  Navigator.pop(context, habit);
                },
                child: const Text('Create Habit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
