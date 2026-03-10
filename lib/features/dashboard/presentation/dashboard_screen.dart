import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/game_state_daily.dart';
import '../../../data/repositories/game_state_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GameStateRepository _gameStateRepository = GameStateRepository();

  GameStateDaily? _state;
  bool _loading = true;

  final TextEditingController _phaseController = TextEditingController();
  final TextEditingController _narrativeController = TextEditingController();
  final TextEditingController _characterController = TextEditingController();
  final TextEditingController _statsController = TextEditingController();
  final TextEditingController _mainQuestController = TextEditingController();
  final TextEditingController _sideQuestsController = TextEditingController();
  final TextEditingController _rulesController = TextEditingController();
  final TextEditingController _rewardsController = TextEditingController();
  final TextEditingController _tutorialController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _questLogController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final state = await _gameStateRepository.getByDate(date);
    if (!mounted) return;
    setState(() {
      _state = state;
      _loading = false;
    });
    _syncControllers(state);
  }

  void _syncControllers(GameStateDaily? state) {
    if (state == null) return;
    _phaseController.text = state.phase ?? '';
    _narrativeController.text = state.narrativeSummary ?? '';
    _characterController.text = _prettyJson(state.characterJson);
    _statsController.text = _prettyJson(state.statsJson);
    _mainQuestController.text = _prettyJson(state.mainQuestJson);
    _sideQuestsController.text = _prettyJson(state.sideQuestsJson);
    _rulesController.text = _prettyJson(state.rulesJson);
    _rewardsController.text = _prettyJson(state.rewardsJson);
    _tutorialController.text = _prettyJson(state.tutorialJson);
    _feedbackController.text = _prettyJson(state.feedbackJson);
    _questLogController.text = _prettyJson(state.questLogJson);
  }

  String _prettyJson(Object? value) {
    return const JsonEncoder.withIndent('  ').convert(value ?? {});
  }

  Object? _decodeJson(String text) {
    if (text.trim().isEmpty) return null;
    return jsonDecode(text);
  }

  Future<void> _saveState() async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final state = GameStateDaily(
        date: date,
        phase: _phaseController.text.trim().isEmpty
            ? null
            : _phaseController.text.trim(),
        characterJson: (_decodeJson(_characterController.text)
                as Map<String, Object?>?) ??
            {},
        statsJson:
            (_decodeJson(_statsController.text) as Map<String, Object?>?) ?? {},
        mainQuestJson: (_decodeJson(_mainQuestController.text)
                as Map<String, Object?>?) ??
            {},
        sideQuestsJson:
            (_decodeJson(_sideQuestsController.text) as List?) ?? [],
        rulesJson: (_decodeJson(_rulesController.text) as List?) ?? [],
        rewardsJson: (_decodeJson(_rewardsController.text) as List?) ?? [],
        tutorialJson: (_decodeJson(_tutorialController.text)
                as Map<String, Object?>?) ??
            {},
        feedbackJson: (_decodeJson(_feedbackController.text)
                as Map<String, Object?>?) ??
            {},
        questLogJson: (_decodeJson(_questLogController.text)
                as Map<String, Object?>?) ??
            {},
        narrativeSummary: _narrativeController.text.trim().isEmpty
            ? null
            : _narrativeController.text.trim(),
        updatedAt: DateTime.now(),
      );
      await _gameStateRepository.upsert(state);
      setState(() {
        _state = state;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dashboard saved.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid JSON in one of the fields.')),
      );
    }
  }

  @override
  void dispose() {
    _phaseController.dispose();
    _narrativeController.dispose();
    _characterController.dispose();
    _statsController.dispose();
    _mainQuestController.dispose();
    _sideQuestsController.dispose();
    _rulesController.dispose();
    _rewardsController.dispose();
    _tutorialController.dispose();
    _feedbackController.dispose();
    _questLogController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, MMM d').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - $dateLabel'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _phaseController,
                  decoration: const InputDecoration(
                    labelText: 'Life phase',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _narrativeController,
                  decoration: const InputDecoration(
                    labelText: 'Narrative summary',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _JsonBlock(
                  label: 'Character assessment + evidence',
                  controller: _characterController,
                ),
                _JsonBlock(label: 'Stats', controller: _statsController),
                _JsonBlock(label: 'Main quest', controller: _mainQuestController),
                _JsonBlock(
                  label: 'Side quests',
                  controller: _sideQuestsController,
                ),
                _JsonBlock(label: 'Rules', controller: _rulesController),
                _JsonBlock(label: 'Rewards', controller: _rewardsController),
                _JsonBlock(label: 'Tutorial plan', controller: _tutorialController),
                _JsonBlock(label: 'Feedback system', controller: _feedbackController),
                _JsonBlock(label: 'Quest log update', controller: _questLogController),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _saveState,
                  icon: const Icon(Icons.save),
                  label: Text(_state == null ? 'Save' : 'Update'),
                ),
              ],
            ),
    );
  }
}

class _JsonBlock extends StatelessWidget {
  const _JsonBlock({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: 6,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
