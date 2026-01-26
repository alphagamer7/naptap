import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class NapRecord {
  final int? id;
  final DateTime startTime;
  final int durationMinutes;
  final bool completed;

  NapRecord({
    this.id,
    required this.startTime,
    required this.durationMinutes,
    required this.completed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'completed': completed ? 1 : 0,
    };
  }

  factory NapRecord.fromMap(Map<String, dynamic> map) {
    return NapRecord(
      id: map['id'] as int?,
      startTime: DateTime.parse(map['start_time'] as String),
      durationMinutes: map['duration_minutes'] as int,
      completed: (map['completed'] as int) == 1,
    );
  }
}

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;

  DatabaseService._();

  static DatabaseService getInstance() {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'naptap.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE nap_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_time TEXT NOT NULL,
            duration_minutes INTEGER NOT NULL,
            completed INTEGER NOT NULL DEFAULT 1
          )
        ''');
      },
    );
  }

  Future<int> insertNapRecord(NapRecord record) async {
    final db = await database;
    return await db.insert('nap_records', record.toMap());
  }

  Future<List<NapRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query('nap_records', orderBy: 'start_time DESC');
    return maps.map((map) => NapRecord.fromMap(map)).toList();
  }

  Future<List<NapRecord>> getRecordsForWeek(DateTime weekStart) async {
    final db = await database;
    final weekEnd = weekStart.add(const Duration(days: 7));

    final maps = await db.query(
      'nap_records',
      where: 'start_time >= ? AND start_time < ?',
      whereArgs: [weekStart.toIso8601String(), weekEnd.toIso8601String()],
      orderBy: 'start_time DESC',
    );
    return maps.map((map) => NapRecord.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getWeeklyStats(DateTime weekStart) async {
    final records = await getRecordsForWeek(weekStart);
    final completedRecords = records.where((r) => r.completed).toList();

    int totalNaps = completedRecords.length;
    int totalMinutes = completedRecords.fold(0, (sum, r) => sum + r.durationMinutes);
    double avgDuration = totalNaps > 0 ? totalMinutes / totalNaps : 0;

    // Count naps per day of week (0 = Monday, 6 = Sunday)
    Map<int, int> napsByDay = {};
    for (var record in completedRecords) {
      int dayOfWeek = record.startTime.weekday - 1; // 0-indexed
      napsByDay[dayOfWeek] = (napsByDay[dayOfWeek] ?? 0) + 1;
    }

    return {
      'totalNaps': totalNaps,
      'totalMinutes': totalMinutes,
      'avgDuration': avgDuration,
      'napsByDay': napsByDay,
      'records': completedRecords,
    };
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete('nap_records', where: 'id = ?', whereArgs: [id]);
  }
}
