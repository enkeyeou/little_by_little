import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/habit_progress.dart';

class HabitProgressLocalDataSource {
  final AppDatabase _appDatabase;

  HabitProgressLocalDataSource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<void> saveProgress(HabitProgress progress) async {
    final db = await _appDatabase.database;

    await db.insert(
      'habit_logs',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<HabitProgress?> getProgress(String habitId, DateTime date) async {
    final db = await _appDatabase.database;

    final dateKey =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final results = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, dateKey],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return HabitProgress.fromMap(results.first);
  }

  Future<List<HabitProgress>> getProgressForDate(DateTime date) async {
    final db = await _appDatabase.database;

    final dateKey =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final results = await db.query(
      'habit_logs',
      where: 'date = ?',
      whereArgs: [dateKey],
    );

    return results.map((map) => HabitProgress.fromMap(map)).toList();
  }

  Future<List<HabitProgress>> getProgressBetweenDates(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _appDatabase.database;

    String formatDate(DateTime date) {
      return '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }

    final results = await db.query(
      'habit_logs',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [formatDate(startDate), formatDate(endDate)],
    );

    return results.map((map) => HabitProgress.fromMap(map)).toList();
  }

  Future<List<HabitProgress>> getProgressForHabit(String habitId) async {
    final db = await _appDatabase.database;

    final results = await db.query(
      'habit_logs',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date ASC',
    );

    return results.map((map) => HabitProgress.fromMap(map)).toList();
  }

  Future<List<HabitProgress>> getProgressForHabits(
    List<String> habitIds,
  ) async {
    if (habitIds.isEmpty) return [];

    final db = await _appDatabase.database;
    final placeholders = List.filled(habitIds.length, '?').join(', ');
    final results = await db.query(
      'habit_logs',
      where: 'habit_id IN ($placeholders)',
      whereArgs: habitIds,
      orderBy: 'date ASC',
    );

    return results.map((map) => HabitProgress.fromMap(map)).toList();
  }
}
