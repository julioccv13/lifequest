import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../services/database_service.dart';

class SettingsRepository {
  SettingsRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  static const _conversationIdKey = 'current_conversation_id';
  Future<AppSettings> getSettings() async {
    final db = await _databaseService.database;
    final rows = await db.query('settings', where: 'id = 1', limit: 1);
    if (rows.isEmpty) {
      final defaults = defaultSettings();
      await saveSettings(defaults);
      return defaults;
    }
    final settings = AppSettings.fromMap(rows.first);
    return AppSettings(
      coachPrompt: settings.coachPrompt,
      extractionPrompt: settings.extractionPrompt,
      schema: settings.schema,
      llmEnabled: settings.llmEnabled,
      llmEndpoint: settings.llmEndpoint,
      llmApiKey: decodeApiKey(settings.llmApiKey),
      timezone: settings.timezone,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final db = await _databaseService.database;
    final map = Map<String, Object?>.from(settings.toMap());
    map['llm_api_key'] = encodeApiKey(settings.llmApiKey);
    await db.insert(
      'settings',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  AppSettings defaultSettings() {
    return AppSettings(
      coachPrompt: _defaultCoachPrompt,
      extractionPrompt: _defaultExtractionPrompt,
      schema: _defaultSchema,
      llmEnabled: false,
      llmEndpoint: null,
      llmApiKey: null,
      timezone: DateTime.now().timeZoneName,
    );
  }

  String encodeApiKey(String? apiKey) {
    if (apiKey == null || apiKey.isEmpty) {
      return '';
    }
    return base64Encode(utf8.encode(apiKey));
  }

  String? decodeApiKey(String? stored) {
    if (stored == null || stored.isEmpty) {
      return null;
    }
    try {
      return utf8.decode(base64Decode(stored));
    } catch (_) {
      return null;
    }
  }

  Future<void> setCurrentConversationId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_conversationIdKey, id);
  }

  Future<String?> getCurrentConversationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_conversationIdKey);
  }

  Future<void> setTimezone(String timezone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timezone', timezone);
  }

  Future<String?> getTimezone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('timezone');
  }
}

const String _defaultCoachPrompt = '''
You are LifeQuest AI: a strategic life coach who gamifies the user's real life into an immersive RPG-style journey. Your job is to help the user identify their current life phase (Limbo, Vision, Flow, Resistance), clarify desires, and translate goals into quests with a coherent narrative.

Operating Modes
- Phase 1 (Assessment & Game Design): diagnose life phase, build the user's game.
- Phase 2 (Ongoing Coaching): maintain quests, update character status, calibrate difficulty.

Rules
- Ask only 1-3 questions at a time when you need info.
- Be honest about uncertainty and ask clarifying questions when needed.
- Avoid generic advice: tailor to what the user actually says.
- Recommend challenges slightly beyond current capability (edge of the unknown).
- Focus on intrinsic motivation, not external rewards.
- Never push actions that conflict with the user's boundaries or values.

Output style
- Use headings and bullet lists.
- Keep it vivid and game-like, but actionable.
''';

const String _defaultExtractionPrompt = '''
You are a data extractor for the LifeQuest app. Convert the user's recent chat into a structured JSON update that matches the provided schema exactly.

Requirements
- Output MUST be valid JSON only. No markdown, no commentary.
- Use only fields defined in the schema.
- If unknown, use null (or empty array if appropriate).
- Prefer conservative inference; do not invent facts.
- Derive "phase" only if there is evidence; otherwise set phase=null and include follow_up_questions (1-3 questions max).
- Keep quests actionable: concrete next steps, small enough to do.
- Ensure difficulty is "slightly beyond current capability" (1-5).
- Maintain continuity: if previous_state is provided, update it rather than resetting.
''';

final Map<String, Object?> _defaultSchema = {
  'date': 'YYYY-MM-DD',
  'phase': 'Limbo|Vision|Flow|Resistance|null',
  'phase_evidence': 'string|null',
  'negative_vision': 'string|null',
  'character_assessment': {
    'strengths': <String>[],
    'weaknesses': <String>[],
    'motivations': <String>[],
    'possible_directions': <String>[],
  },
  'stats': {
    'clarity': 'number|null',
    'energy': 'number|null',
    'discipline': 'number|null',
    'courage': 'number|null',
    'focus': 'number|null',
    'connection': 'number|null',
  },
  'game_design': {
    'main_quest': {'title': 'string|null', 'why': 'string|null'},
    'side_quests': <Object?>[],
    'rules': <String>[],
    'rewards': <String>[],
    'level_system': {
      'level_name': 'string|null',
      'xp_rules': <String>[],
      'level_markers': <String>[],
    },
  },
  'tutorial_phase': {
    'week_1': <String>[],
    'week_2': <String>[],
  },
  'feedback_system': {
    'daily_checkin': <String>[],
    'weekly_review': <String>[],
  },
  'quest_log_update': {
    'progress_notes': 'string|null',
    'completed_quests': <String>[],
    'blocked_quests': <String>[],
  },
  'follow_up_questions': <String>[],
};
