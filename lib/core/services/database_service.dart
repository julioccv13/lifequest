import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }
    final path = kIsWeb ? 'lifequest_web.db' : await _nativeDbPath();
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createTables(db);
        }
      },
    );
  }

  Future<String> _nativeDbPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, 'lifequest.db');
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        title TEXT,
        created_at INTEGER
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT,
        role TEXT,
        content TEXT,
        created_at INTEGER
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS game_state_daily (
        date TEXT PRIMARY KEY,
        phase TEXT,
        character_json TEXT,
        stats_json TEXT,
        main_quest_json TEXT,
        side_quests_json TEXT,
        rules_json TEXT,
        rewards_json TEXT,
        tutorial_json TEXT,
        feedback_json TEXT,
        quest_log_json TEXT,
        narrative_summary TEXT,
        updated_at INTEGER
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quests (
        id TEXT PRIMARY KEY,
        type TEXT,
        title TEXT,
        description TEXT,
        domain TEXT,
        difficulty INTEGER,
        xp INTEGER,
        status TEXT,
        steps_json TEXT,
        created_at INTEGER,
        updated_at INTEGER
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS checkins (
        id TEXT PRIMARY KEY,
        date TEXT,
        mood INTEGER,
        energy INTEGER,
        focus INTEGER,
        notes TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY,
        coach_prompt TEXT,
        extraction_prompt TEXT,
        schema_json TEXT,
        llm_enabled INTEGER,
        llm_endpoint TEXT,
        llm_api_key TEXT,
        timezone TEXT
      );
    ''');
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('messages');
      await txn.delete('conversations');
      await txn.delete('game_state_daily');
      await txn.delete('quests');
      await txn.delete('checkins');
      await txn.delete('settings');
    });
  }

  Future<void> close() async {
    if (_db == null) return;
    await _db!.close();
    _db = null;
  }
}
