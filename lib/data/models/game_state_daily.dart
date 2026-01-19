import 'dart:convert';

class GameStateDaily {
  GameStateDaily({
    required this.date,
    required this.phase,
    required this.characterJson,
    required this.statsJson,
    required this.mainQuestJson,
    required this.sideQuestsJson,
    required this.rulesJson,
    required this.rewardsJson,
    required this.tutorialJson,
    required this.feedbackJson,
    required this.questLogJson,
    required this.narrativeSummary,
    required this.updatedAt,
  });

  final String date;
  final String? phase;
  final Map<String, Object?> characterJson;
  final Map<String, Object?> statsJson;
  final Map<String, Object?> mainQuestJson;
  final List<Object?> sideQuestsJson;
  final List<Object?> rulesJson;
  final List<Object?> rewardsJson;
  final Map<String, Object?> tutorialJson;
  final Map<String, Object?> feedbackJson;
  final Map<String, Object?> questLogJson;
  final String? narrativeSummary;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'date': date,
      'phase': phase,
      'character_json': jsonEncode(characterJson),
      'stats_json': jsonEncode(statsJson),
      'main_quest_json': jsonEncode(mainQuestJson),
      'side_quests_json': jsonEncode(sideQuestsJson),
      'rules_json': jsonEncode(rulesJson),
      'rewards_json': jsonEncode(rewardsJson),
      'tutorial_json': jsonEncode(tutorialJson),
      'feedback_json': jsonEncode(feedbackJson),
      'quest_log_json': jsonEncode(questLogJson),
      'narrative_summary': narrativeSummary,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  static GameStateDaily fromMap(Map<String, Object?> map) {
    return GameStateDaily(
      date: map['date'] as String,
      phase: map['phase'] as String?,
      characterJson: _decodeMap(map['character_json']),
      statsJson: _decodeMap(map['stats_json']),
      mainQuestJson: _decodeMap(map['main_quest_json']),
      sideQuestsJson: _decodeList(map['side_quests_json']),
      rulesJson: _decodeList(map['rules_json']),
      rewardsJson: _decodeList(map['rewards_json']),
      tutorialJson: _decodeMap(map['tutorial_json']),
      feedbackJson: _decodeMap(map['feedback_json']),
      questLogJson: _decodeMap(map['quest_log_json']),
      narrativeSummary: map['narrative_summary'] as String?,
      updatedAt: _decodeDate(map['updated_at']),
    );
  }

  static Map<String, Object?> _decodeMap(Object? value) {
    if (value == null) return <String, Object?>{};
    if (value is Map<String, Object?>) return value;
    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return <String, Object?>{};
  }

  static List<Object?> _decodeList(Object? value) {
    if (value == null) return <Object?>[];
    if (value is List) return value;
    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded;
    }
    return <Object?>[];
  }

  static DateTime _decodeDate(Object? value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
