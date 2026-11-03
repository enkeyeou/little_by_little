import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'little_by_little.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        emoji TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        tracking_type TEXT NOT NULL,
        counter_goal INTEGER,
        counter_unit TEXT NOT NULL,
        counter_goal_period TEXT NOT NULL,
        schedule_type TEXT NOT NULL,
        selected_weekdays TEXT NOT NULL,
        every_n_days INTEGER NOT NULL,
        weekly_target INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await _createHabitLogsTable(db);
    await _createDailyTasksTable(db);
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createHabitLogsTable(db);
    }
    if (oldVersion < 3) {
      await _createDailyTasksTable(db);
    }
    if (oldVersion < 4) {
      final columns = await db.rawQuery('PRAGMA table_info(daily_tasks)');

      final hasPinnedColumn = columns.any(
        (column) => column['name'] == 'is_pinned',
      );

      if (!hasPinnedColumn) {
        await db.execute('''
      ALTER TABLE daily_tasks
      ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0
    ''');
      }
    }
  }

  Future<void> _createHabitLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE habit_logs (
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        count INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (habit_id, date)
      )
    ''');
  }

  Future<void> _createDailyTasksTable(Database db) async {
    await db.execute('''
    CREATE TABLE daily_tasks (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      date TEXT NOT NULL,
      is_completed INTEGER NOT NULL DEFAULT 0,
      is_pinned INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL
    )
  ''');
  }
}
