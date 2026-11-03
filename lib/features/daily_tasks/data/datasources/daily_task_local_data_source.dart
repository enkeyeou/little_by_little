import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/daily_task.dart';

class DailyTaskLocalDataSource {
  final AppDatabase _appDatabase;

  DailyTaskLocalDataSource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<void> insertTask(DailyTask task) async {
    final db = await _appDatabase.database;

    await db.insert(
      'daily_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DailyTask>> getTasksForDate(DateTime date) async {
    final db = await _appDatabase.database;

    final dateKey = _formatDate(date);

    final results = await db.query(
      'daily_tasks',
      where: 'date = ?',
      whereArgs: [dateKey],
      orderBy: 'created_at ASC',
    );

    return results.map((map) => DailyTask.fromMap(map)).toList();
  }

  Future<List<DailyTask>> getAllTasks() async {
    final db = await _appDatabase.database;

    final results = await db.query(
      'daily_tasks',
      orderBy: 'date ASC, created_at ASC',
    );

    return results.map((map) => DailyTask.fromMap(map)).toList();
  }

  Future<void> updateTask(DailyTask task) async {
    final db = await _appDatabase.database;

    await db.update(
      'daily_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await _appDatabase.database;

    await db.delete('daily_tasks', where: 'id = ?', whereArgs: [id]);
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
