import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/leaderboard_models.dart';
import '../providers/gamification_provider.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gamification = context.watch<GamificationProvider>();

    if (gamification.isLoading && gamification.entries.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leaderboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bronze'),
              Tab(text: 'Silver'),
              Tab(text: 'Gold'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (gamification.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  gamification.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _LeagueList(league: 'bronze', entries: gamification.entries),
                  _LeagueList(league: 'argent', entries: gamification.entries),
                  _LeagueList(league: 'or', entries: gamification.entries),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueList extends StatelessWidget {
  const _LeagueList({required this.league, required this.entries});

  final String league;
  final List<LeaderboardEntryModel> entries;

  @override
  Widget build(BuildContext context) {
    final leagueEntries = entries.where((e) => e.currentLeague == league).toList();

    if (leagueEntries.isEmpty) {
      return const Center(child: Text('No users in this league yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leagueEntries.length,
      itemBuilder: (context, index) {
        final entry = leagueEntries[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(entry.rank.toString())),
            title: Text(entry.fullName),
            subtitle: Text('${entry.weeklyXp} XP this week • Lv ${entry.currentLevel}'),
            trailing: const Icon(Icons.emoji_events_outlined),
          ),
        );
      },
    );
  }
}
