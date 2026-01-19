import 'dart:convert';

class AppSettings {
  AppSettings({
    required this.coachPrompt,
    required this.extractionPrompt,
    required this.schema,
    required this.llmEnabled,
    this.llmEndpoint,
    this.llmApiKey,
    required this.timezone,
  });

  final String coachPrompt;
  final String extractionPrompt;
  final Map<String, Object?> schema;
  final bool llmEnabled;
  final String? llmEndpoint;
  final String? llmApiKey;
  final String timezone;

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'coach_prompt': coachPrompt,
      'extraction_prompt': extractionPrompt,
      'schema_json': jsonEncode(schema),
      'llm_enabled': llmEnabled ? 1 : 0,
      'llm_endpoint': llmEndpoint,
      'llm_api_key': llmApiKey,
      'timezone': timezone,
    };
  }

  static AppSettings fromMap(Map<String, Object?> map) {
    return AppSettings(
      coachPrompt: (map['coach_prompt'] as String?) ?? '',
      extractionPrompt: (map['extraction_prompt'] as String?) ?? '',
      schema: _decodeSchema(map['schema_json']),
      llmEnabled: (map['llm_enabled'] as int? ?? 0) == 1,
      llmEndpoint: map['llm_endpoint'] as String?,
      llmApiKey: map['llm_api_key'] as String?,
      timezone: (map['timezone'] as String?) ?? '',
    );
  }

  static Map<String, Object?> _decodeSchema(Object? value) {
    if (value == null) {
      return <String, Object?>{};
    }
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return <String, Object?>{};
  }
}
