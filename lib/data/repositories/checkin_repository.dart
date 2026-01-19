import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/checkin.dart';
import '../services/database_service.dart';

class CheckinRepository {
  CheckinRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;
  final Uuid _uuid = const Uuid();

  Future<Checkin?> getByDate(String date) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'checkins',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Checkin.fromMap(rows.first);
  }

  Future<List<Checkin>> getAll() async {
    final db = await _databaseService.database;
    final rows = await db.query('checkins', orderBy: 'date DESC');
    return rows.map(Checkin.fromMap).toList();
  }

  Future<Checkin> upsert({
    required String date,
    int? mood,
    int? energy,
    int? focus,
    String? notes,
  }) async {
    final existing = await getByDate(date);
    final checkin = Checkin(
      id: existing?.id ?? _uuid.v4(),
      date: date,
      mood: mood,
      energy: energy,
      focus: focus,
      notes: notes,
    );
    final db = await _databaseService.database;
    await db.insert(
      'checkins',
      checkin.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return checkin;
  }
}
