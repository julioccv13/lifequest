import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/models/checkin.dart';
import '../../data/models/quest.dart';
import '../../data/models/game_state_daily.dart';
import '../../data/repositories/checkin_repository.dart';
import '../../data/repositories/game_state_repository.dart';
import '../../data/repositories/quest_repository.dart';
import '../../data/repositories/settings_repository.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final CheckinRepository _checkinRepository = CheckinRepository();
  final QuestRepository _questRepository = QuestRepository();
  final GameStateRepository _gameStateRepository = GameStateRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();

  List<Checkin> _checkins = [];
  List<Quest> _quests = [];
  GameStateDaily? _latestState;
  bool _loading = true;
  bool _llmEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final checkins = await _checkinRepository.getAll();
    final quests = await _questRepository.getAll();
    final state = await _gameStateRepository.getLatest();
    final settings = await _settingsRepository.getSettings();
    setState(() {
      _checkins = checkins;
      _quests = quests;
      _latestState = state;
      _llmEnabled = settings.llmEnabled;
      _loading = false;
    });
  }

  List<Checkin> _checkinsInDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _checkins.where((checkin) {
      final date = DateTime.tryParse(checkin.date);
      return date != null && date.isAfter(cutoff);
    }).toList();
  }

  double _average(List<Checkin> checkins, int? Function(Checkin) selector) {
    final values = checkins
        .map(selector)
        .whereType<int>()
        .map((value) => value.toDouble())
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  int _completedQuestsCount(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _quests.where((quest) {
      final updated = quest.updatedAt;
      return quest.status == 'completed' && updated.isAfter(cutoff);
    }).length;
  }

  int _checkinStreak() {
    if (_checkins.isEmpty) return 0;
    final dates = _checkins
        .map((checkin) => DateTime.tryParse(checkin.date))
        .whereType<DateTime>()
        .toSet();
    var streak = 0;
    var cursor = DateTime.now();
    while (dates.contains(DateTime(cursor.year, cursor.month, cursor.day))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _autoRecap() {
    final weekly = _checkinsInDays(7);
    final mood = _average(weekly, (item) => item.mood).toStringAsFixed(1);
    final energy = _average(weekly, (item) => item.energy).toStringAsFixed(1);
    final focus = _average(weekly, (item) => item.focus).toStringAsFixed(1);
    return 'Weekly recap: Mood $mood, Energy $energy, Focus $focus.';
  }

  @override
  Widget build(BuildContext context) {
    final weekly = _checkinsInDays(7);
    final monthly = _checkinsInDays(30);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Weekly summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Completed quests',
                  value: _completedQuestsCount(7).toDouble(),
                ),
                _SummaryRow(label: 'Check-in streak', value: _checkinStreak().toDouble()),
                _SummaryRow(
                  label: 'Mood',
                  value: _average(weekly, (item) => item.mood),
                ),
                _SummaryRow(
                  label: 'Energy',
                  value: _average(weekly, (item) => item.energy),
                ),
                _SummaryRow(
                  label: 'Focus',
                  value: _average(weekly, (item) => item.focus),
                ),
                const SizedBox(height: 16),
                Text(
                  'Monthly summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Completed quests',
                  value: _completedQuestsCount(30).toDouble(),
                ),
                _SummaryRow(
                  label: 'Mood',
                  value: _average(monthly, (item) => item.mood),
                ),
                _SummaryRow(
                  label: 'Energy',
                  value: _average(monthly, (item) => item.energy),
                ),
                _SummaryRow(
                  label: 'Focus',
                  value: _average(monthly, (item) => item.focus),
                ),
                const SizedBox(height: 16),
                Text(
                  'Trends',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _ChartBlock(
                  title: 'Mood',
                  checkins: monthly,
                  selector: (item) => item.mood,
                ),
                _ChartBlock(
                  title: 'Energy',
                  checkins: monthly,
                  selector: (item) => item.energy,
                ),
                _ChartBlock(
                  title: 'Focus',
                  checkins: monthly,
                  selector: (item) => item.focus,
                ),
                const SizedBox(height: 16),
                Text(
                  'Narrative recap',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _llmEnabled && _latestState?.narrativeSummary != null
                      ? _latestState!.narrativeSummary!
                      : _autoRecap(),
                ),
              ],
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text(value.toStringAsFixed(1)),
    );
  }
}

class _ChartBlock extends StatelessWidget {
  const _ChartBlock({
    required this.title,
    required this.checkins,
    required this.selector,
  });

  final String title;
  final List<Checkin> checkins;
  final int? Function(Checkin) selector;

  @override
  Widget build(BuildContext context) {
    final points = checkins.reversed.toList().asMap().entries.map((item) {
      final value = selector(item.value) ?? 0;
      return FlSpot(item.key.toDouble(), value.toDouble());
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
