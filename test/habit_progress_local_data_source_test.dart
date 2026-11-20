import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:little_by_little/core/database/app_database.dart';
import 'package:little_by_little/features/habits/data/datasources/habit_progress_local_data_source.dart';
import 'package:little_by_little/features/habits/domain/models/habit_progress.dart';

void main() {
  late Database database;
  late HabitProgressLocalDataSource dataSource;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE habit_logs (
              habit_id TEXT NOT NULL,
              date TEXT NOT NULL,
              is_completed INTEGER NOT NULL DEFAULT 0,
              count INTEGER NOT NULL DEFAULT 0,
              PRIMARY KEY (habit_id, date)
            )
          ''');
        },
      ),
    );

    dataSource = HabitProgressLocalDataSource(
      appDatabase: AppDatabase.forTesting(database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('saves a new historical progress record', () async {
    final progress = HabitProgress(
      habitId: 'habit-1',
      date: DateTime(2026, 10, 15),
      isCompleted: true,
    );

    await dataSource.saveProgress(progress);

    final savedProgress = await dataSource.getProgress(
      'habit-1',
      DateTime(2026, 10, 15),
    );

    expect(savedProgress, isNotNull);
    expect(savedProgress!.habitId, 'habit-1');
    expect(savedProgress.isCompleted, true);
    expect(savedProgress.count, 0);
  });
  test('updates an existing historical progress record', () async {
    final originalProgress = HabitProgress(
      habitId: 'habit-1',
      date: DateTime(2026, 10, 15),
      isCompleted: false,
    );

    await dataSource.saveProgress(originalProgress);

    final updatedProgress = HabitProgress(
      habitId: 'habit-1',
      date: DateTime(2026, 10, 15),
      isCompleted: true,
    );

    await dataSource.saveProgress(updatedProgress);

    final savedProgress = await dataSource.getProgress(
      'habit-1',
      DateTime(2026, 10, 15),
    );

    expect(savedProgress, isNotNull);
    expect(savedProgress!.isCompleted, true);

    final allProgress = await dataSource.getProgressForHabit('habit-1');
    expect(allProgress.length, 1);
  });
  test('saves a historical counter value of zero', () async {
    final progress = HabitProgress(
      habitId: 'habit-2',
      date: DateTime(2026, 10, 16),
      isCompleted: false,
      count: 0,
    );

    await dataSource.saveProgress(progress);

    final savedProgress = await dataSource.getProgress(
      'habit-2',
      DateTime(2026, 10, 16),
    );

    expect(savedProgress, isNotNull);
    expect(savedProgress!.count, 0);
    expect(savedProgress.isCompleted, false);
  });
  test('editing one date does not affect another date', () async {
    await dataSource.saveProgress(
      HabitProgress(
        habitId: 'habit-1',
        date: DateTime(2026, 10, 15),
        isCompleted: true,
      ),
    );

    await dataSource.saveProgress(
      HabitProgress(
        habitId: 'habit-1',
        date: DateTime(2026, 10, 16),
        isCompleted: false,
      ),
    );

    // Edit only October 15.
    await dataSource.saveProgress(
      HabitProgress(
        habitId: 'habit-1',
        date: DateTime(2026, 10, 15),
        isCompleted: false,
      ),
    );

    final october15 = await dataSource.getProgress(
      'habit-1',
      DateTime(2026, 10, 15),
    );

    final october16 = await dataSource.getProgress(
      'habit-1',
      DateTime(2026, 10, 16),
    );

    expect(october15!.isCompleted, false);
    expect(october16!.isCompleted, false);

    final allProgress = await dataSource.getProgressForHabit('habit-1');
    expect(allProgress.length, 2);
  });
}
