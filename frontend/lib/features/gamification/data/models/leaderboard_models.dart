class LeaderboardEntryModel {
  const LeaderboardEntryModel({
    required this.rank,
    required this.fullName,
    required this.weeklyXp,
    required this.currentLeague,
    required this.currentLevel,
    required this.totalXp,
  });

  final int rank;
  final String fullName;
  final int weeklyXp;
  final String currentLeague;
  final int currentLevel;
  final int totalXp;

  factory LeaderboardEntryModel.fromApi(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: json['rank'] as int,
      fullName: (json['full_name'] as String?) ?? 'Anonymous',
      weeklyXp: json['weekly_xp'] as int,
      currentLeague: ((json['current_league'] as String?) ?? 'bronze').toLowerCase(),
      currentLevel: json['current_level'] as int? ?? 1,
      totalXp: json['total_xp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'full_name': fullName,
      'weekly_xp': weeklyXp,
      'current_league': currentLeague,
      'current_level': currentLevel,
      'total_xp': totalXp,
    };
  }
}
