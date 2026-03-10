import 'dart:convert';

import 'package:http/http.dart' as http;

class LlmService {
  Future<String> chat({
    required String endpoint,
    required String coachPrompt,
    required List<Map<String, Object?>> messages,
    String? apiKey,
  }) async {
    final payload = {
      'mode': 'chat',
      'coach_prompt': coachPrompt,
      'messages': messages,
    };

    final decoded = await _post(endpoint, payload, apiKey);
    if (decoded['assistant_message'] == null) {
      throw Exception('LLM response missing assistant_message.');
    }
    return decoded['assistant_message'].toString();
  }

  Future<Map<String, Object?>> extract({
    required String endpoint,
    required String coachPrompt,
    required String extractionPrompt,
    required Map<String, Object?> schema,
    required List<Map<String, Object?>> messages,
    Map<String, Object?>? previousState,
    List<Map<String, Object?>>? activeQuests,
    String? apiKey,
  }) async {
    final payload = {
      'mode': 'extract',
      'coach_prompt': coachPrompt,
      'extraction_prompt': extractionPrompt,
      'schema': schema,
      'messages': messages,
      'previous_state': previousState,
      'quests': activeQuests,
    };

    final decoded = await _post(endpoint, payload, apiKey);
    return decoded;
  }

  Future<Map<String, Object?>> _post(
    String endpoint,
    Map<String, Object?> payload,
    String? apiKey,
  ) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('LLM request failed with ${response.statusCode}.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('LLM response was not a JSON object.');
    }
    return decoded;
  }
}
