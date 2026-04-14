class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.totalXp,
    required this.level,
    required this.streak,
    required this.weeklyXp,
    required this.currentLeague,
    required this.role,
  });

  final int id;
  final String email;
  final String fullName;
  final String avatarUrl;
  final String sourceLanguage;
  final String targetLanguage;
  final int totalXp;
  final int level;
  final int streak;
  final int weeklyXp;
  final String currentLeague;
  final String role;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: (json['full_name'] as String?) ?? 'Learner',
      avatarUrl: json['avatar_url'] as String? ?? '',
      sourceLanguage: (json['source_language'] as String? ?? '').trim().toLowerCase(),
      targetLanguage: (json['target_language'] as String? ?? '').trim().toLowerCase(),
      totalXp: json['total_xp'] as int? ?? 0,
      level: json['current_level'] as int? ?? 1,
      streak: json['streak_count'] as int? ?? 0,
      weeklyXp: json['weekly_xp'] as int? ?? 0,
      currentLeague: (json['current_league'] as String?) ?? 'bronze',
      role: ((json['role'] as String?) ?? 'student').toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'total_xp': totalXp,
      'current_level': level,
      'streak_count': streak,
      'weekly_xp': weeklyXp,
      'current_league': currentLeague,
      'role': role,
    };
  }

  UserProfileModel copyWith({
    String? fullName,
    String? avatarUrl,
    String? sourceLanguage,
    String? targetLanguage,
    int? totalXp,
    int? level,
    int? streak,
    int? weeklyXp,
    String? currentLeague,
    String? role,
  }) {
    return UserProfileModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      currentLeague: currentLeague ?? this.currentLeague,
      role: role ?? this.role,
    );
  }
}
