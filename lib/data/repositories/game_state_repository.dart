import 'package:sqflite/sqflite.dart';

import '../models/game_state_daily.dart';
import '../../core/services/database_service.dart';

class GameStateRepository {
  GameStateRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  Future<GameStateDaily?> getByDate(String date) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'game_state_daily',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return GameStateDaily.fromMap(rows.first);
  }

  Future<GameStateDaily?> getLatest() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'game_state_daily',
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return GameStateDaily.fromMap(rows.first);
  }

  Future<GameStateDaily> upsert(GameStateDaily state) async {
    final db = await _databaseService.database;
    await db.insert(
      'game_state_daily',
      state.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return state;
  }
}
