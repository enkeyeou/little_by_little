import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/habits/presentation/screens/add_habit_screen.dart';
import '../features/habits/domain/models/habit.dart';
import '../features/habits/data/datasources/habit_local_data_source.dart';
import '../features/daily_tasks/domain/models/daily_task.dart';
import '../features/daily_tasks/data/datasources/daily_task_local_data_source.dart';
import '../features/daily_tasks/presentation/screens/daily_tasks_screen.dart';
import '../features/daily_tasks/presentation/screens/add_daily_task_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final List<Habit> _habits = [];
  final HabitLocalDataSource _habitDataSource = HabitLocalDataSource();
  final List<DailyTask> _dailyTasks = [];
  final List<DailyTask> _allDailyTasks = [];
  final DailyTaskLocalDataSource _dailyTaskDataSource =
      DailyTaskLocalDataSource();
  DateTime _selectedTaskDate = DateTime.now();

  List<Widget> get _pages => [
    HomeScreen(
      habits: _habits,
      onHabitUpdated: _updateHabit,
      onHabitDeleted: _deleteHabit,
    ),
    DailyTasksScreen(
      tasks: _dailyTasks,
      allTasks: _allDailyTasks,
      selectedDate: _selectedTaskDate,
      onDateChanged: _selectTaskDate,
      onTaskTapped: _openEditTaskScreen,
      onTaskUpdated: _updateDailyTask,
    ),
    const Center(child: Text('Insights')),
    const Center(child: Text('History')),
    const Center(child: Text('Settings')),
  ];

  @override
  void initState() {
    super.initState();
    _loadHabits();
    _loadDailyTasks(DateTime.now());
  }

  Future<void> _loadHabits() async {
    final savedHabits = await _habitDataSource.getAllHabits();

    if (!mounted) return;

    setState(() {
      _habits.addAll(savedHabits);
    });
  }

  Future<void> _selectTaskDate(DateTime date) async {
    setState(() {
      _selectedTaskDate = date;
    });
    await _loadDailyTasks(date);
  }

  Future<void> _addDailyTask(DailyTask task) async {
    try {
      await _dailyTaskDataSource.insertTask(task);

      if (!mounted) return;

      await _loadDailyTasks(_selectedTaskDate);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add task. Please try again.')),
      );
    }
  }

  Future<void> _openAddTaskScreen() async {
    final task = await Navigator.push<DailyTask>(
      context,
      MaterialPageRoute(
        builder: (context) => AddDailyTaskScreen(
          initialDate: _selectedTaskDate,
          onDelete: (_) {},
        ),
      ),
    );

    if (task != null) {
      await _addDailyTask(task);
    }
  }

  Future<void> _openEditTaskScreen(DailyTask existingTask) async {
    final updatedTask = await Navigator.push<DailyTask>(
      context,
      MaterialPageRoute(
        builder: (context) => AddDailyTaskScreen(
          initialDate: existingTask.date,
          task: existingTask,
          onDelete: _deleteDailyTask,
        ),
      ),
    );

    if (updatedTask != null) {
      await _updateDailyTask(updatedTask);
    }
  }

  Future<void> _updateDailyTask(DailyTask task) async {
    try {
      await _dailyTaskDataSource.updateTask(task);

      if (!mounted) return;

      await _loadDailyTasks(_selectedTaskDate);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update task. Please try again.'),
        ),
      );
    }
  }

  Future<void> _deleteDailyTask(String id) async {
    try {
      await _dailyTaskDataSource.deleteTask(id);

      if (!mounted) return;
      await _loadDailyTasks(_selectedTaskDate);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete task. Please try again.'),
        ),
      );
    }
  }

  Future<void> _loadDailyTasks(DateTime date) async {
    final results = await Future.wait([
      _dailyTaskDataSource.getTasksForDate(date),
      _dailyTaskDataSource.getAllTasks(),
    ]);

    final savedTasks = results[0];
    final allSavedTasks = results[1];

    if (!mounted) return;

    setState(() {
      _dailyTasks
        ..clear()
        ..addAll(savedTasks);

      _allDailyTasks
        ..clear()
        ..addAll(allSavedTasks);
    });
  }

  Future<void> _updateHabit(Habit habit) async {
    try {
      await _habitDataSource.updateHabit(habit);

      if (!mounted) return;

      setState(() {
        final index = _habits.indexWhere((item) => item.id == habit.id);

        if (index != -1) {
          _habits[index] = habit;
        }
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update habit. Please try again.'),
        ),
      );
    }
  }

  Future<bool> _deleteHabit(String id) async {
    try {
      await _habitDataSource.deleteHabit(id);

      if (!mounted) return false;

      setState(() {
        _habits.removeWhere((habit) => habit.id == id);
      });

      return true;
    } catch (error) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete habit. Please try again.'),
        ),
      );

      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _selectedIndex == 0
                  ? () async {
                      final habit = await Navigator.push<Habit>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddHabitScreen(),
                        ),
                      );

                      if (habit != null) {
                        try {
                          await _habitDataSource.insertHabit(habit);

                          if (!mounted) return;

                          setState(() {
                            _habits.add(habit);
                          });
                        } catch (error, stackTrace) {
                          debugPrint('Failed to save habit: $error');
                          debugPrintStack(stackTrace: stackTrace);

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not save habit: $error'),
                            ),
                          );
                        }
                      }
                    }
                  : _openAddTaskScreen,
              icon: const Icon(Icons.add),
              label: Text(_selectedIndex == 0 ? 'Add Habit' : 'Add Task'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
