import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/platform/file_download_stub.dart'
    if (dart.library.html) '../../../core/platform/file_download_web.dart';
import '../../../core/platform/local_file_io_stub.dart'
    if (dart.library.io) '../../../core/platform/local_file_io_io.dart';
import '../../../core/services/database_service.dart';
import '../../../core/widgets/load_error_view.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/repositories/settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    SettingsRepository? settingsRepository,
    DatabaseService? databaseService,
  })  : _settingsRepository = settingsRepository,
        _databaseService = databaseService;

  final SettingsRepository? _settingsRepository;
  final DatabaseService? _databaseService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsRepository _settingsRepository =
      widget._settingsRepository ?? SettingsRepository();
  late final DatabaseService _databaseService =
      widget._databaseService ?? DatabaseService.instance;

  final TextEditingController _coachPromptController = TextEditingController();
  final TextEditingController _extractPromptController =
      TextEditingController();
  final TextEditingController _schemaController = TextEditingController();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _timezoneController = TextEditingController();

  bool _llmEnabled = false;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final settings = await _settingsRepository.getSettings();
      if (!mounted) return;
      _coachPromptController.text = settings.coachPrompt;
      _extractPromptController.text = settings.extractionPrompt;
      _schemaController.text =
          const JsonEncoder.withIndent('  ').convert(settings.schema);
      _endpointController.text = settings.llmEndpoint ?? '';
      _apiKeyController.text = settings.llmApiKey ?? '';
      _timezoneController.text = settings.timezone;
      setState(() {
        _llmEnabled = settings.llmEnabled;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Unable to load settings.';
      });
      debugPrint('SettingsScreen load error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    final schema = _parseSchema(_schemaController.text.trim());
    if (schema.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schema JSON is invalid.')),
      );
      return;
    }

    final settings = AppSettings(
      coachPrompt: _coachPromptController.text.trim(),
      extractionPrompt: _extractPromptController.text.trim(),
      schema: schema,
      llmEnabled: _llmEnabled,
      llmEndpoint: _endpointController.text.trim(),
      llmApiKey: _apiKeyController.text.trim(),
      timezone: _timezoneController.text.trim(),
    );
    await _settingsRepository.saveSettings(settings);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved.')),
    );
  }

  Map<String, Object?> _parseSchema(String text) {
    if (text.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return {};
    }
    return {};
  }

  Future<void> _exportData() async {
    final db = await _databaseService.database;
    final conversations = await db.query('conversations');
    final messages = await db.query('messages');
    final states = await db.query('game_state_daily');
    final quests = await db.query('quests');
    final checkins = await db.query('checkins');
    final settings = await db.query('settings');

    final payload = {
      'conversations': conversations,
      'messages': messages,
      'game_state_daily': states,
      'quests': quests,
      'checkins': checkins,
      'settings': settings.isNotEmpty ? settings.first : null,
    };

    final content = const JsonEncoder.withIndent('  ').convert(payload);
    if (kIsWeb) {
      final date = DateTime.now().toIso8601String().split('T').first;
      downloadTextFile('lifequest_export_$date.json', content);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export downloaded.')),
      );
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/lifequest_export.json';
    await writeTextFile(path, content);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported to $path')),
    );
  }

  Future<void> _importData() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }
      final bytes = result.files.single.bytes;
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read file.')),
        );
        return;
      }
      final payload = jsonDecode(utf8.decode(bytes));
      await _restoreFromPayload(payload);
      return;
    }

    final controller = TextEditingController();
    final path = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import JSON'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Path to JSON file',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (path == null || path.isEmpty) {
      return;
    }

    if (!await fileExists(path)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found.')),
      );
      return;
    }

    final payload = jsonDecode(await readTextFile(path));
    await _restoreFromPayload(payload);
  }

  Future<void> _restoreFromPayload(Object? payload) async {
    if (payload is! Map) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid JSON file.')),
      );
      return;
    }

    final db = await _databaseService.database;
    await _databaseService.clearAll();

    Future<void> insertList(String key, String table) async {
      final items = (payload[key] as List?) ?? [];
      for (final item in items) {
        if (item is Map) {
          await db.insert(table, item.cast<String, Object?>());
        }
      }
    }

    await insertList('conversations', 'conversations');
    await insertList('messages', 'messages');
    await insertList('game_state_daily', 'game_state_daily');
    await insertList('quests', 'quests');
    await insertList('checkins', 'checkins');

    final settings = payload['settings'];
    if (settings is Map) {
      await db.insert('settings', settings.cast<String, Object?>());
    }

    await _loadSettings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import completed.')),
    );
  }

  @override
  void dispose() {
    _coachPromptController.dispose();
    _extractPromptController.dispose();
    _schemaController.dispose();
    _endpointController.dispose();
    _apiKeyController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? LoadErrorView(
                  message: _loadError!,
                  onRetry: _loadSettings,
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextField(
                      controller: _coachPromptController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Coach prompt',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _extractPromptController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Extraction prompt',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _schemaController,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        labelText: 'Schema JSON',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Enable LLM'),
                      value: _llmEnabled,
                      onChanged: (value) {
                        setState(() {
                          _llmEnabled = value;
                        });
                      },
                    ),
                    TextField(
                      controller: _endpointController,
                      decoration: const InputDecoration(
                        labelText: 'LLM endpoint URL',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        labelText: 'API key (stored locally; not fully secure)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _timezoneController,
                      decoration: const InputDecoration(
                        labelText: 'Timezone (device default)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Save settings'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _exportData,
                      icon: const Icon(Icons.file_download),
                      label: const Text('Export data to JSON'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _importData,
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Import data from JSON'),
                    ),
                  ],
                ),
    );
  }
}
