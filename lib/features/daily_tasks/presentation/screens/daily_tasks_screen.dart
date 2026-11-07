import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/daily_task.dart';
import '../widgets/daily_task_calendar.dart';
import '../widgets/daily_task_list.dart';

class DailyTasksScreen extends StatefulWidget {
  final List<DailyTask> tasks;
  final List<DailyTask> allTasks;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<DailyTask> onTaskUpdated;
  final ValueChanged<DailyTask> onTaskTapped;

  const DailyTasksScreen({
    super.key,
    required this.tasks,
    required this.allTasks,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onTaskUpdated,
    required this.onTaskTapped,
  });

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  final ScrollController _taskScrollController = ScrollController();

  @override
  void dispose() {
    _taskScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          controller: _taskScrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Tasks',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'One step at a time. One task at a time.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              DailyTaskCalendar(
                allTasks: widget.allTasks,
                selectedDate: widget.selectedDate,
                onDateChanged: widget.onDateChanged,
              ),
              const SizedBox(height: 24),
              DailyTaskList(
                tasks: widget.tasks,
                onTaskUpdated: widget.onTaskUpdated,
                onTaskTapped: widget.onTaskTapped,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
