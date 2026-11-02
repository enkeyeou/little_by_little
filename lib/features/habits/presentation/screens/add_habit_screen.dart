import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  String _selectedEmoji = '🌱';
  Color _selectedColor = AppColors.primary;
  String _trackingType = 'Completion';
  String _counterGoal = '';
  String _counterUnit = 'times';
  String _counterGoalPeriod = 'Daily';

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
              decoration: InputDecoration(
                hintText: 'e.g. Read for 15 minutes',
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
                },
                decoration: InputDecoration(
                  hintText: 'e.g. 8',
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
                },
                decoration: InputDecoration(
                  hintText: 'e.g. glasses, pages, minutes',
                  labelText: 'Unit',
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
          ],
        ),
      ),
    );
  }
}
