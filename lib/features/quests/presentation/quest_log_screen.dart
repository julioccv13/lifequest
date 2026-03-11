import 'package:flutter/material.dart';

import '../../../core/widgets/load_error_view.dart';
import '../../../data/models/quest.dart';
import '../../../data/repositories/quest_repository.dart';

class QuestLogScreen extends StatefulWidget {
  const QuestLogScreen({
    super.key,
    QuestRepository? questRepository,
  }) : _questRepository = questRepository;

  final QuestRepository? _questRepository;

  @override
  State<QuestLogScreen> createState() => _QuestLogScreenState();
}

class _QuestLogScreenState extends State<QuestLogScreen> {
  late final QuestRepository _questRepository =
      widget._questRepository ?? QuestRepository();

  List<Quest> _quests = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final quests = await _questRepository.getAll();
      if (!mounted) return;
      setState(() {
        _quests = quests;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Unable to load quests.';
      });
      debugPrint('QuestLogScreen load error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _createOrEditQuest({Quest? quest}) async {
    final titleController = TextEditingController(text: quest?.title ?? '');
    final descriptionController =
        TextEditingController(text: quest?.description ?? '');
    final typeController = TextEditingController(text: quest?.type ?? 'side');
    final domainController =
        TextEditingController(text: quest?.domain ?? 'other');
    final difficultyController =
        TextEditingController(text: quest?.difficulty.toString() ?? '1');
    final xpController =
        TextEditingController(text: quest?.xp.toString() ?? '0');
    final statusController =
        TextEditingController(text: quest?.status ?? 'active');
    final stepsController = TextEditingController(
      text: quest?.steps.map((step) => step.title).join(', ') ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(quest == null ? 'New quest' : 'Edit quest'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                    labelText: 'Type (main|side|tutorial)'),
              ),
              TextField(
                controller: domainController,
                decoration: const InputDecoration(labelText: 'Domain'),
              ),
              TextField(
                controller: difficultyController,
                decoration:
                    const InputDecoration(labelText: 'Difficulty (1-5)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: xpController,
                decoration: const InputDecoration(labelText: 'XP reward'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: statusController,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              TextField(
                controller: stepsController,
                decoration: const InputDecoration(
                  labelText: 'Steps (comma-separated)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final steps = stepsController.text
        .split(',')
        .map((step) => step.trim())
        .where((step) => step.isNotEmpty)
        .map((step) => QuestStep(title: step, done: false))
        .toList();

    if (quest == null) {
      await _questRepository.create(
        type: typeController.text.trim(),
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        domain: domainController.text.trim(),
        difficulty: int.tryParse(difficultyController.text) ?? 1,
        xp: int.tryParse(xpController.text) ?? 0,
        status: statusController.text.trim(),
        steps: steps,
      );
    } else {
      final updated = Quest(
        id: quest.id,
        type: typeController.text.trim(),
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        domain: domainController.text.trim(),
        difficulty: int.tryParse(difficultyController.text) ?? quest.difficulty,
        xp: int.tryParse(xpController.text) ?? quest.xp,
        status: statusController.text.trim(),
        steps: steps,
        createdAt: quest.createdAt,
        updatedAt: DateTime.now(),
      );
      await _questRepository.upsert(updated);
    }

    await _loadQuests();
  }

  Future<void> _toggleStep(Quest quest, int index) async {
    final steps = quest.steps
        .asMap()
        .entries
        .map((entry) => QuestStep(
              title: entry.value.title,
              done: entry.key == index ? !entry.value.done : entry.value.done,
            ))
        .toList();
    await _questRepository.updateSteps(quest.id, steps);
    await _loadQuests();
  }

  Future<void> _toggleStatus(Quest quest) async {
    final nextStatus = quest.status == 'completed' ? 'active' : 'completed';
    await _questRepository.updateStatus(quest.id, nextStatus);
    await _loadQuests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quest Log'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? LoadErrorView(
                  message: _loadError!,
                  onRetry: _loadQuests,
                )
              : _quests.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No quests yet. Add one to start tracking progress.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _quests.length,
                      itemBuilder: (context, index) {
                        final quest = _quests[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        quest.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _createOrEditQuest(quest: quest),
                                      icon: const Icon(Icons.edit),
                                    ),
                                    IconButton(
                                      onPressed: () => _toggleStatus(quest),
                                      icon: Icon(
                                        quest.status == 'completed'
                                            ? Icons.undo
                                            : Icons.check_circle,
                                      ),
                                    ),
                                  ],
                                ),
                                Text('${quest.type} - ${quest.domain}'),
                                Text(
                                    'Difficulty ${quest.difficulty} - XP ${quest.xp}'),
                                if (quest.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(quest.description),
                                  ),
                                const SizedBox(height: 8),
                                ...quest.steps.asMap().entries.map(
                                      (entry) => CheckboxListTile(
                                        value: entry.value.done,
                                        onChanged: (_) =>
                                            _toggleStep(quest, entry.key),
                                        title: Text(entry.value.title),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrEditQuest(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
