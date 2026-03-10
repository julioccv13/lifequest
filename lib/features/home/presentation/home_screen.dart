import 'package:flutter/material.dart';

import '../../chat/presentation/chat_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../insights/presentation/insights_screen.dart';
import '../../quests/presentation/quest_log_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final List<Widget> _screens = const [
    ChatScreen(),
    DashboardScreen(),
    QuestLogScreen(),
    InsightsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Quest Log'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Insights'),
        ],
      ),
    );
  }
}
