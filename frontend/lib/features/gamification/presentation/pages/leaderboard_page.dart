import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/leaderboard_models.dart';
import '../providers/gamification_provider.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gamification = context.watch<GamificationProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subdued = scheme.onSurface.withOpacity(0.75);

    if (gamification.isLoading && gamification.entries.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00D1C1)),
        ),
      );
    }

    final entries = [...gamification.entries]
      ..sort((a, b) {
        final rankCompare = a.rank.compareTo(b.rank);
        if (rankCompare != 0) {
          return rankCompare;
        }
        return b.totalXp.compareTo(a.totalXp);
      });

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Leaderboard',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (gamification.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                gamification.error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),

          // Top description
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
              "Compete with learners worldwide.\nEarn XP by completing lessons and quizzes!",
              style: TextStyle(fontSize: 14, color: subdued, height: 1.5),
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('No users available yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _LeaderboardTile(entry: entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry});

  final LeaderboardEntryModel entry;

  ImageProvider<Object>? _avatarImage(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('data:image')) {
      final commaIndex = trimmed.indexOf(',');
      if (commaIndex < 0 || commaIndex + 1 >= trimmed.length) return null;
      final encoded = trimmed.substring(commaIndex + 1);
      try {
        return MemoryImage(base64Decode(encoded));
      } catch (_) {
        return null;
      }
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subdued = scheme.onSurface.withOpacity(0.75);

    final avatar = _avatarImage(entry.avatarUrl);
    final isTop3 = entry.rank <= 3;
    final top3TextColor = isTop3 ? Colors.black : subdued;

    // Define styles based on rank
    Color borderColor = theme.dividerColor.withOpacity(0.6);
    Color backgroundColor = scheme.surface;
    Widget rankIndicator = Text(
      '${entry.rank}',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: subdued,
      ),
    );

    if (entry.rank == 1) {
      borderColor = const Color(0xFFFFD700); // Gold
      backgroundColor = const Color(0xFFFFFDF0); // Very light gold tint
      rankIndicator = const Icon(
        Icons.workspace_premium_rounded,
        color: Color(0xFFFFD700),
        size: 28,
      );
    } else if (entry.rank == 2) {
      borderColor = const Color(0xFFC0C0C0); // Silver
      backgroundColor = const Color(0xFFF8F9FA); // Very light grey tint
      rankIndicator = const Icon(
        Icons.workspace_premium_rounded,
        color: Color(0xFFC0C0C0),
        size: 28,
      );
    } else if (entry.rank == 3) {
      borderColor = const Color(0xFFCD7F32); // Bronze
      backgroundColor = const Color(0xFFFFF9F5); // Very light bronze tint
      rankIndicator = const Icon(
        Icons.workspace_premium_rounded,
        color: Color(0xFFCD7F32),
        size: 28,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isTop3 ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Rank Indicator (Number or Crown)
          SizedBox(width: 30, child: Center(child: rankIndicator)),
          const SizedBox(width: 12),

          // 2. Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isTop3 ? borderColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFF0F0F0),
              backgroundImage: avatar,
              child: avatar == null
                  ? Text(
                      entry.fullName.isNotEmpty
                          ? entry.fullName.substring(0, 1).toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: top3TextColor,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),

          // 3. Name & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isTop3 ? Colors.black : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Level ${entry.currentLevel} • ${entry.totalXp} XP total',
                  style: TextStyle(fontSize: 13, color: top3TextColor),
                ),
              ],
            ),
          ),

          // 4. Weekly XP (Highlighted)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'This Week',
                style: TextStyle(
                  fontSize: 10,
                  color: isTop3 ? Colors.black : subdued.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.weeklyXp} XP',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF00D1C1), // Teal highlight
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
