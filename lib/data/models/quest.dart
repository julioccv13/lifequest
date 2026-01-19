import 'dart:convert';

class QuestStep {
  QuestStep({required this.title, required this.done});

  final String title;
  final bool done;

  Map<String, Object?> toJson() => {
        'title': title,
        'done': done,
      };

  static QuestStep fromJson(Map<String, Object?> json) {
    return QuestStep(
      title: json['title'] as String? ?? '',
      done: json['done'] as bool? ?? false,
    );
  }

  static String encodeList(List<QuestStep> steps) {
    return jsonEncode(steps.map((step) => step.toJson()).toList());
  }
}

class Quest {
  Quest({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.domain,
    required this.difficulty,
    required this.xp,
    required this.status,
    required this.steps,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final String domain;
  final int difficulty;
  final int xp;
  final String status;
  final List<QuestStep> steps;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'domain': domain,
      'difficulty': difficulty,
      'xp': xp,
      'status': status,
      'steps_json': jsonEncode(steps.map((step) => step.toJson()).toList()),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  static Quest fromMap(Map<String, Object?> map) {
    return Quest(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      domain: map['domain'] as String,
      difficulty: (map['difficulty'] as int?) ?? 1,
      xp: (map['xp'] as int?) ?? 0,
      status: map['status'] as String,
      steps: _decodeSteps(map['steps_json']),
      createdAt: _decodeDate(map['created_at']),
      updatedAt: _decodeDate(map['updated_at']),
    );
  }

  static List<QuestStep> _decodeSteps(Object? value) {
    if (value == null) return <QuestStep>[];
    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => QuestStep.fromJson(item.cast<String, Object?>()))
            .toList();
      }
    }
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => QuestStep.fromJson(item.cast<String, Object?>()))
          .toList();
    }
    return <QuestStep>[];
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
