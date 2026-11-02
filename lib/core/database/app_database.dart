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
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(
    Database db,
    int version,
  ) async {
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
  }
}