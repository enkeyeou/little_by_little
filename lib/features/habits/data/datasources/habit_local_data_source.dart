import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/habit.dart';

class HabitLocalDataSource {
  final AppDatabase _appDatabase;

  HabitLocalDataSource({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<void> insertHabit(Habit habit) async {
    final db = await _appDatabase.database;

    await db.insert(
      'habits',
      habit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Habit>> getAllHabits() async {
    final db = await _appDatabase.database;

    final results = await db.query('habits', orderBy: 'created_at DESC');

    return results.map((map) => Habit.fromMap(map)).toList();
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await _appDatabase.database;

    await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<void> deleteHabit(String id) async {
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      await txn.delete('habit_logs', where: 'habit_id = ?', whereArgs: [id]);

      await txn.delete('habits', where: 'id = ?', whereArgs: [id]);
    });
  }
}