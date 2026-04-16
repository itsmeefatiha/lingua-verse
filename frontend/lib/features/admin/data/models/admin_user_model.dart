class AdminUserModel {
  const AdminUserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
    required this.role,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.isActive,
    required this.totalXp,
    required this.currentLevel,
    required this.weeklyXp,
    required this.currentLeague,
    required this.streakCount,
    required this.createdAt,
  });

  final int id;
  final String email;
  final String fullName;
  final String avatarUrl;
  final String role;
  final String sourceLanguage;
  final String targetLanguage;
  final bool isActive;
  final int totalXp;
  final int currentLevel;
  final int weeklyXp;
  final String currentLeague;
  final int streakCount;
  final DateTime? createdAt;

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as int,
      email: (json['email'] as String?) ?? '',
      fullName: (json['full_name'] as String?) ?? 'Unknown',
      avatarUrl: (json['avatar_url'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'user',
      sourceLanguage: (json['source_language'] as String?) ?? 'fr',
      targetLanguage: (json['target_language'] as String?) ?? 'en',
      isActive: json['is_active'] as bool? ?? false,
      totalXp: json['total_xp'] as int? ?? 0,
      currentLevel: json['current_level'] as int? ?? 1,
      weeklyXp: json['weekly_xp'] as int? ?? 0,
      currentLeague: (json['current_league'] as String?) ?? 'bronze',
      streakCount: json['streak_count'] as int? ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }
}
