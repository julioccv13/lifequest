import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifequest/app/lifequest_app.dart';
import 'package:lifequest/core/services/database_service.dart';
import 'package:lifequest/data/models/app_settings.dart';
import 'package:lifequest/data/models/quest.dart';
import 'package:lifequest/data/repositories/chat_repository.dart';
import 'package:lifequest/data/repositories/quest_repository.dart';
import 'package:lifequest/data/repositories/settings_repository.dart';
import 'package:lifequest/features/chat/presentation/chat_screen.dart';
import 'package:lifequest/features/quests/presentation/quest_log_screen.dart';
import 'package:lifequest/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const LifeQuestApp());
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxAttempts = 20,
}) async {
  for (var i = 0; i < maxAttempts; i += 1) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return '/tmp/lifequest_test';
          }
          return null;
        });
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseService.instance.close();
    await DatabaseService.instance.clearAll();
  });

  tearDown(() async {
    await DatabaseService.instance.close();
  });

  testWidgets('renders main navigation including settings', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Chat'), findsWidgets);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Quest Log'), findsWidgets);
    expect(find.text('Insights'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('chat screen renders creation controls', (WidgetTester tester) async {
    await _pumpScreen(tester, const ChatScreen());
    await _pumpUntilFound(tester, find.byType(FloatingActionButton));

    expect(find.text('Chat'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('quest log screen renders creation controls', (
    WidgetTester tester,
  ) async {
    await _pumpScreen(tester, const QuestLogScreen());
    await _pumpUntilFound(tester, find.byType(FloatingActionButton));

    expect(find.text('Quest Log'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('settings screen renders main actions', (WidgetTester tester) async {
    await _pumpScreen(tester, const SettingsScreen());
    await _pumpUntilFound(tester, find.text('Settings'));

    expect(find.text('Settings'), findsOneWidget);
  });

  test('chat repository stores conversations and messages', () async {
    final repository = ChatRepository();

    final conversation = await repository.createConversation(title: 'Daily Planning');
    await repository.addMessage(
      conversationId: conversation.id,
      role: 'user',
      content: 'Plan my day',
    );

    final conversations = await repository.getConversations();
    final messages = await repository.getMessagesForConversation(conversation.id);

    expect(conversations.map((item) => item.title), contains('Daily Planning'));
    expect(messages, hasLength(1));
    expect(messages.first.content, 'Plan my day');
  });

  test('quest repository creates and updates quests', () async {
    final repository = QuestRepository();

    final quest = await repository.create(
      type: 'side',
      title: 'Morning Run',
      description: 'Run for 20 minutes',
      domain: 'health',
      difficulty: 2,
      xp: 50,
      status: 'active',
      steps: [
        QuestStep(title: 'Warm up', done: false),
        QuestStep(title: 'Run', done: false),
      ],
    );

    await repository.updateStatus(quest.id, 'completed');

    final quests = await repository.getAll();

    expect(quests, hasLength(1));
    expect(quests.first.title, 'Morning Run');
    expect(quests.first.status, 'completed');
  });

  test('settings repository persists api key and defaults', () async {
    final repository = SettingsRepository();
    final defaults = await repository.getSettings();

    expect(defaults.schema, isNotEmpty);

    await repository.saveSettings(
      AppSettings(
        coachPrompt: defaults.coachPrompt,
        extractionPrompt: defaults.extractionPrompt,
        schema: defaults.schema,
        llmEnabled: true,
        llmEndpoint: 'https://example.com/llm',
        llmApiKey: 'secret-key',
        timezone: 'UTC',
      ),
    );

    final saved = await repository.getSettings();

    expect(saved.llmEnabled, isTrue);
    expect(saved.llmEndpoint, 'https://example.com/llm');
    expect(saved.llmApiKey, 'secret-key');
    expect(saved.timezone, 'UTC');
  });
}
