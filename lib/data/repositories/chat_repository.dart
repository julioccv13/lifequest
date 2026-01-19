import 'package:uuid/uuid.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../services/database_service.dart';

class ChatRepository {
  ChatRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;
  final Uuid _uuid = const Uuid();

  Future<Conversation> createConversation({String? title}) async {
    final conversation = Conversation(
      id: _uuid.v4(),
      title: title,
      createdAt: DateTime.now(),
    );
    final db = await _databaseService.database;
    await db.insert('conversations', conversation.toMap());
    return conversation;
  }

  Future<void> addMessage({
    required String conversationId,
    required String role,
    required String content,
  }) async {
    final message = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: role,
      content: content,
      createdAt: DateTime.now(),
    );
    final db = await _databaseService.database;
    await db.insert('messages', message.toMap());
  }

  Future<List<Message>> getMessagesForConversation(String conversationId) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Message.fromMap).toList();
  }

  Future<List<Conversation>> getConversations() async {
    final db = await _databaseService.database;
    final rows = await db.query('conversations', orderBy: 'created_at DESC');
    return rows.map(Conversation.fromMap).toList();
  }

  Future<List<Message>> getMessagesForDate({
    required String conversationId,
    required DateTime date,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final db = await _databaseService.database;
    final rows = await db.query(
      'messages',
      where:
          'conversation_id = ? AND created_at >= ? AND created_at < ?',
      whereArgs: [
        conversationId,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'created_at ASC',
    );
    return rows.map(Message.fromMap).toList();
  }
}
