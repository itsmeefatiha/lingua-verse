class LeaderboardEntryModel {
  const LeaderboardEntryModel({
    required this.rank,
    required this.fullName,
    required this.avatarUrl,
    required this.weeklyXp,
    required this.currentLevel,
    required this.totalXp,
  });

  final int rank;
  final String fullName;
  final String avatarUrl;
  final int weeklyXp;
  final int currentLevel;
  final int totalXp;

  factory LeaderboardEntryModel.fromApi(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: json['rank'] as int,
      fullName: (json['full_name'] as String?) ?? 'Anonymous',
      avatarUrl: (json['avatar_url'] as String?) ?? '',
      weeklyXp: json['weekly_xp'] as int,
      currentLevel: json['current_level'] as int? ?? 1,
      totalXp: json['total_xp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'weekly_xp': weeklyXp,
      'current_level': currentLevel,
      'total_xp': totalXp,
    };
  }
}
