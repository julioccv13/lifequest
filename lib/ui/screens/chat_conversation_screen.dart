import 'package:flutter/material.dart';

import '../../data/models/message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/game_state_repository.dart';
import '../../data/repositories/quest_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/llm_service.dart';
import '../../domain/usecases/generate_state_from_chat.dart';
import 'settings_screen.dart';

class ChatConversationScreen extends StatefulWidget {
  const ChatConversationScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  final String conversationId;
  final String title;

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final ChatRepository _chatRepository = ChatRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();
  final GameStateRepository _gameStateRepository = GameStateRepository();
  final QuestRepository _questRepository = QuestRepository();
  final GenerateStateFromChat _generateState = GenerateStateFromChat();
  final LlmService _llmService = LlmService();

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _loading = true;
  bool _generating = false;
  bool _sending = false;
  String _phaseLabel = 'Unknown';
  List<String> _activeQuestTitles = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final messages =
        await _chatRepository.getMessagesForConversation(widget.conversationId);
    final latestState = await _gameStateRepository.getLatest();
    final activeQuests = await _questRepository.getActive();
    setState(() {
      _messages = messages;
      _loading = false;
      _phaseLabel = latestState?.phase ?? 'Unknown';
      _activeQuestTitles = activeQuests.map((quest) => quest.title).toList();
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() {
      _sending = true;
    });

    await _chatRepository.addMessage(
      conversationId: widget.conversationId,
      role: 'user',
      content: text,
    );

    final settings = await _settingsRepository.getSettings();
    if (settings.llmEnabled &&
        settings.llmEndpoint != null &&
        settings.llmEndpoint!.isNotEmpty) {
      try {
        final history = await _chatRepository.getMessagesForConversation(
          widget.conversationId,
        );
        final recent = history.length > 12
            ? history.sublist(history.length - 12)
            : history;
        final assistant = await _llmService.chat(
          endpoint: settings.llmEndpoint!,
          coachPrompt: settings.coachPrompt,
          messages: recent
              .map((message) => {
                    'role': message.role,
                    'content': message.content,
                    'created_at': message.createdAt.millisecondsSinceEpoch,
                  })
              .toList(),
          apiKey: settings.llmApiKey,
        );
        await _chatRepository.addMessage(
          conversationId: widget.conversationId,
          role: 'assistant',
          content: assistant,
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('LLM chat failed.')),
        );
      }
    }

    await _refresh();
    if (mounted) {
      setState(() {
        _sending = false;
      });
    }
  }

  Future<void> _completeCheckIn() async {
    setState(() {
      _generating = true;
    });
    try {
      await _generateState(
        date: DateTime.now(),
        conversationId: widget.conversationId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Today\'s status updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Extraction failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _generating = false;
        });
      }
      await _refresh();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Phase: $_phaseLabel'),
                const SizedBox(height: 4),
                Text(
                  _activeQuestTitles.isEmpty
                      ? 'Active Quests: None'
                      : 'Active Quests: ${_activeQuestTitles.join(', ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message.role == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(message.content),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Message LifeQuest AI...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sending ? null : _sendMessage,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generating ? null : _completeCheckIn,
                    icon: const Icon(Icons.check_circle),
                    label: Text(
                      _generating
                          ? 'Generating...'
                          : 'Generate/Update Today\'s Status',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
