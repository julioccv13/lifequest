import 'package:flutter/material.dart';

import '../../../data/models/conversation.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import 'chat_conversation_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatRepository _chatRepository = ChatRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();
  final TextEditingController _titleController = TextEditingController();

  List<Conversation> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final conversations = await _chatRepository.getConversations();
    setState(() {
      _conversations = conversations;
      _loading = false;
    });
  }

  Future<void> _createConversation() async {
    final title = _titleController.text.trim();
    final conversation = await _chatRepository.createConversation(
      title: title.isEmpty ? 'New conversation' : title,
    );
    await _settingsRepository.setCurrentConversationId(conversation.id);
    _titleController.clear();
    await _loadConversations();
    if (!mounted) return;
    _openConversation(conversation);
  }

  void _openConversation(Conversation conversation) {
    _settingsRepository.setCurrentConversationId(conversation.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(
          conversationId: conversation.id,
          title: conversation.title ?? 'Conversation',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final conversation = _conversations[index];
                return ListTile(
                  title: Text(conversation.title ?? 'Conversation'),
                  subtitle: Text(conversation.createdAt.toLocal().toString()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openConversation(conversation),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('New conversation'),
              content: TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _createConversation();
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
