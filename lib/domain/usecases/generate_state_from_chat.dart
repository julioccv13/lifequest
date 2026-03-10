import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/game_state_daily.dart';
import '../../data/models/quest.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/checkin_repository.dart';
import '../../data/repositories/game_state_repository.dart';
import '../../data/repositories/quest_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../core/services/llm_service.dart';

class GenerateStateFromChat {
  GenerateStateFromChat({
    ChatRepository? chatRepository,
    GameStateRepository? gameStateRepository,
    QuestRepository? questRepository,
    CheckinRepository? checkinRepository,
    SettingsRepository? settingsRepository,
    LlmService? llmService,
  })  : _chatRepository = chatRepository ?? ChatRepository(),
        _gameStateRepository = gameStateRepository ?? GameStateRepository(),
        _questRepository = questRepository ?? QuestRepository(),
        _checkinRepository = checkinRepository ?? CheckinRepository(),
        _settingsRepository = settingsRepository ?? SettingsRepository(),
        _llmService = llmService ?? LlmService();

  final ChatRepository _chatRepository;
  final GameStateRepository _gameStateRepository;
  final QuestRepository _questRepository;
  final CheckinRepository _checkinRepository;
  final SettingsRepository _settingsRepository;
  final LlmService _llmService;
  final Uuid _uuid = const Uuid();

  Future<GameStateDaily> call({
    required DateTime date,
    required String conversationId,
  }) async {
    final settings = await _settingsRepository.getSettings();
    final messages = await _chatRepository.getMessagesForDate(
      conversationId: conversationId,
      date: date,
    );
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final previous = await _gameStateRepository.getByDate(
      DateFormat('yyyy-MM-dd').format(date.subtract(const Duration(days: 1))),
    );
    final activeQuests = await _questRepository.getActive();

    if (settings.llmEnabled &&
        settings.llmEndpoint != null &&
        settings.llmEndpoint!.isNotEmpty) {
      final response = await _llmService.extract(
        endpoint: settings.llmEndpoint!,
        coachPrompt: settings.coachPrompt,
        extractionPrompt: settings.extractionPrompt,
        schema: settings.schema,
        messages: messages
            .map((message) => {
                  'role': message.role,
                  'content': message.content,
                  'created_at': message.createdAt.millisecondsSinceEpoch,
                })
            .toList(),
        previousState: previous == null ? null : _stateToSchema(previous),
        activeQuests: activeQuests
            .map((quest) => {
                  'id': quest.id,
                  'type': quest.type,
                  'title': quest.title,
                  'description': quest.description,
                  'domain': quest.domain,
                  'difficulty': quest.difficulty,
                  'xp': quest.xp,
                  'status': quest.status,
                  'steps': quest.steps
                      .map((step) => step.toJson())
                      .toList(),
                })
            .toList(),
        apiKey: settings.llmApiKey,
      );

      final state = _decodeMap(response['state']);
      final quests = response['quests'] as List? ?? [];
      final checkin = _decodeMap(response['checkin']);

      final dailyState = _stateFromSchema(dateKey, state);
      await _gameStateRepository.upsert(dailyState);

      for (final quest in quests) {
        if (quest is Map) {
          final parsed = _questFromMap(quest.cast<String, Object?>());
          await _questRepository.upsert(parsed);
        }
      }

      await _checkinRepository.upsert(
        date: dateKey,
        mood: _toInt(checkin['mood']),
        energy: _toInt(checkin['energy']),
        focus: _toInt(checkin['focus']),
        notes: checkin['notes']?.toString(),
      );
    
      return dailyState;
    }

    final empty = GameStateDaily(
      date: dateKey,
      phase: null,
      characterJson: const {},
      statsJson: const {},
      mainQuestJson: const {},
      sideQuestsJson: const [],
      rulesJson: const [],
      rewardsJson: const [],
      tutorialJson: const {},
      feedbackJson: const {},
      questLogJson: const {},
      narrativeSummary: null,
      updatedAt: DateTime.now(),
    );
    await _gameStateRepository.upsert(empty);
    return empty;
  }

  GameStateDaily _stateFromSchema(String dateKey, Map<String, Object?> state) {
    final gameDesign = _decodeMap(state['game_design']);
    final character = _decodeMap(state['character_assessment']);
    final feedback = _decodeMap(state['feedback_system']);
    final questLog = _decodeMap(state['quest_log_update']);

    final characterJson = <String, Object?>{
      'character_assessment': character,
      'phase_evidence': state['phase_evidence'],
      'negative_vision': state['negative_vision'],
    };
    final feedbackJson = <String, Object?>{
      'feedback_system': feedback,
      'follow_up_questions': state['follow_up_questions'],
    };

    return GameStateDaily(
      date: dateKey,
      phase: state['phase']?.toString(),
      characterJson: characterJson,
      statsJson: _decodeMap(state['stats']),
      mainQuestJson: _decodeMap(gameDesign['main_quest']),
      sideQuestsJson: _decodeList(gameDesign['side_quests']),
      rulesJson: _decodeList(gameDesign['rules']),
      rewardsJson: _decodeList(gameDesign['rewards']),
      tutorialJson: _decodeMap(state['tutorial_phase']),
      feedbackJson: feedbackJson,
      questLogJson: questLog,
      narrativeSummary: state['narrative_summary']?.toString(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, Object?> _stateToSchema(GameStateDaily state) {
    final character = state.characterJson['character_assessment']
            as Map<String, Object?>? ??
        {};
    final feedback = state.feedbackJson['feedback_system']
            as Map<String, Object?>? ??
        {};
    return {
      'date': state.date,
      'phase': state.phase,
      'phase_evidence': state.characterJson['phase_evidence'],
      'negative_vision': state.characterJson['negative_vision'],
      'character_assessment': character,
      'stats': state.statsJson,
      'game_design': {
        'main_quest': state.mainQuestJson,
        'side_quests': state.sideQuestsJson,
        'rules': state.rulesJson,
        'rewards': state.rewardsJson,
        'level_system': {},
      },
      'tutorial_phase': state.tutorialJson,
      'feedback_system': feedback,
      'quest_log_update': state.questLogJson,
      'follow_up_questions': state.feedbackJson['follow_up_questions'] ?? [],
    };
  }

  Quest _questFromMap(Map<String, Object?> json) {
    final steps = _decodeList(json['steps'])
        .whereType<Map>()
        .map((item) => QuestStep.fromJson(item.cast<String, Object?>()))
        .toList();
    final id = json['id']?.toString();
    return Quest(
      id: (id == null || id.isEmpty) ? _uuid.v4() : id,
      type: json['type']?.toString() ?? 'side',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      domain: json['domain']?.toString() ?? 'other',
      difficulty: _toInt(json['difficulty']) ?? 1,
      xp: _toInt(json['xp']) ?? 0,
      status: json['status']?.toString() ?? 'active',
      steps: steps,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, Object?> _decodeMap(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) {
      return value.cast<String, Object?>();
    }
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return decoded.cast<String, Object?>();
        }
      } catch (_) {
        return <String, Object?>{};
      }
    }
    return <String, Object?>{};
  }

  List<Object?> _decodeList(Object? value) {
    if (value is List) return value;
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded;
        }
      } catch (_) {
        return <Object?>[];
      }
    }
    return <Object?>[];
  }
}
