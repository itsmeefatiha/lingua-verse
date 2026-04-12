class AdminTopUserModel {
  const AdminTopUserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.totalXp,
    required this.currentLevel,
    required this.streakCount,
    required this.currentLeague,
  });

  final int userId;
  final String fullName;
  final String email;
  final int totalXp;
  final int currentLevel;
  final int streakCount;
  final String currentLeague;

  factory AdminTopUserModel.fromJson(Map<String, dynamic> json) {
    return AdminTopUserModel(
      userId: json['user_id'] as int,
      fullName: (json['full_name'] as String?) ?? 'Unknown',
      email: json['email'] as String,
      totalXp: json['total_xp'] as int? ?? 0,
      currentLevel: json['current_level'] as int? ?? 1,
      streakCount: json['streak_count'] as int? ?? 0,
      currentLeague: (json['current_league'] as String?) ?? 'bronze',
    );
  }
}

class AdminDashboardStatsModel {
  const AdminDashboardStatsModel({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.adminUsers,
    required this.teacherUsers,
    required this.studentUsers,
    required this.totalXpDistributed,
    required this.averageXp,
    required this.bronzeUsers,
    required this.argentUsers,
    required this.orUsers,
    required this.topUsers,
  });

  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int adminUsers;
  final int teacherUsers;
  final int studentUsers;
  final int totalXpDistributed;
  final double averageXp;
  final int bronzeUsers;
  final int argentUsers;
  final int orUsers;
  final List<AdminTopUserModel> topUsers;

  factory AdminDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStatsModel(
      totalUsers: json['total_users'] as int? ?? 0,
      activeUsers: json['active_users'] as int? ?? 0,
      inactiveUsers: json['inactive_users'] as int? ?? 0,
      adminUsers: json['admin_users'] as int? ?? 0,
      teacherUsers: json['teacher_users'] as int? ?? 0,
      studentUsers: json['student_users'] as int? ?? 0,
      totalXpDistributed: json['total_xp_distributed'] as int? ?? 0,
      averageXp: (json['average_xp'] as num?)?.toDouble() ?? 0,
      bronzeUsers: json['bronze_users'] as int? ?? 0,
      argentUsers: json['argent_users'] as int? ?? 0,
      orUsers: json['or_users'] as int? ?? 0,
      topUsers: (json['top_users'] as List<dynamic>? ?? [])
          .map((item) => AdminTopUserModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
