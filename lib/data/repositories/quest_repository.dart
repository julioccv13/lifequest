import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/quest.dart';
import '../../core/services/database_service.dart';

class QuestRepository {
  QuestRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;
  final Uuid _uuid = const Uuid();

  Future<List<Quest>> getAll() async {
    final db = await _databaseService.database;
    final rows = await db.query('quests', orderBy: 'updated_at DESC');
    return rows.map(Quest.fromMap).toList();
  }

  Future<List<Quest>> getActive() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'quests',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'updated_at DESC',
    );
    return rows.map(Quest.fromMap).toList();
  }

  Future<Quest> create({
    required String type,
    required String title,
    required String description,
    required String domain,
    required int difficulty,
    required int xp,
    required String status,
    required List<QuestStep> steps,
  }) async {
    final quest = Quest(
      id: _uuid.v4(),
      type: type,
      title: title,
      description: description,
      domain: domain,
      difficulty: difficulty,
      xp: xp,
      status: status,
      steps: steps,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final db = await _databaseService.database;
    await db.insert('quests', quest.toMap());
    return quest;
  }

  Future<void> upsert(Quest quest) async {
    final db = await _databaseService.database;
    await db.insert(
      'quests',
      quest.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateStatus(String id, String status) async {
    final db = await _databaseService.database;
    await db.update(
      'quests',
      {
        'status': status,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateSteps(String id, List<QuestStep> steps) async {
    final db = await _databaseService.database;
    await db.update(
      'quests',
      {
        'steps_json': QuestStep.encodeList(steps),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
