class ProgressLessonModel {
  const ProgressLessonModel({
    required this.lessonId,
    required this.lessonTitle,
    required this.progressPercent,
  });

  final int lessonId;
  final String lessonTitle;
  final double progressPercent;

  factory ProgressLessonModel.fromApi(Map<String, dynamic> json) {
    return ProgressLessonModel(
      lessonId: json['lesson_id'] as int,
      lessonTitle: json['lesson_title'] as String? ?? 'Lesson',
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ProgressLevelModel {
  const ProgressLevelModel({
    required this.levelId,
    required this.levelName,
    required this.levelCode,
    required this.progressPercent,
    required this.completedLessons,
    required this.totalLessons,
  });

  final int levelId;
  final String levelName;
  final String levelCode;
  final double progressPercent;
  final int completedLessons;
  final int totalLessons;

  factory ProgressLevelModel.fromApi(Map<String, dynamic> json) {
    return ProgressLevelModel(
      levelId: json['level_id'] as int,
      levelName: json['level_name'] as String? ?? 'Level',
      levelCode: json['level_code'] as String? ?? '',
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
      completedLessons: json['completed_lessons'] as int? ?? 0,
      totalLessons: json['total_lessons'] as int? ?? 0,
    );
  }
}

class ProgressOverviewModel {
  const ProgressOverviewModel({
    required this.userId,
    required this.overallCompletionPercent,
    required this.completedLessons,
    required this.totalLessons,
    required this.lessons,
    required this.levels,
  });

  final int userId;
  final double overallCompletionPercent;
  final int completedLessons;
  final int totalLessons;
  final List<ProgressLessonModel> lessons;
  final List<ProgressLevelModel> levels;

  factory ProgressOverviewModel.fromApi(Map<String, dynamic> json) {
    return ProgressOverviewModel(
      userId: json['user_id'] as int,
      overallCompletionPercent: (json['overall_completion_percent'] as num?)?.toDouble() ?? 0,
      completedLessons: json['completed_lessons'] as int? ?? 0,
      totalLessons: json['total_lessons'] as int? ?? 0,
        lessons: (json['lessons'] as List<dynamic>? ?? [])
          .map((item) => ProgressLessonModel.fromApi(item as Map<String, dynamic>))
          .toList(),
      levels: (json['levels'] as List<dynamic>? ?? [])
          .map((item) => ProgressLevelModel.fromApi(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LanguageTimeEntryModel {
  const LanguageTimeEntryModel({required this.languageCode, required this.durationMinutes});

  final String languageCode;
  final double durationMinutes;

  factory LanguageTimeEntryModel.fromApi(Map<String, dynamic> json) {
    return LanguageTimeEntryModel(
      languageCode: json['language_code'] as String? ?? 'n/a',
      durationMinutes: (json['duration_minutes'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ThemeSuccessModel {
  const ThemeSuccessModel({required this.theme, required this.successRate});

  final String theme;
  final double successRate;

  factory ThemeSuccessModel.fromApi(Map<String, dynamic> json) {
    return ThemeSuccessModel(
      theme: json['theme'] as String? ?? 'general',
      successRate: (json['success_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AnalyticsDashboardModel {
  const AnalyticsDashboardModel({
    required this.totalXp,
    required this.weeklyXp,
    required this.streakCount,
    required this.currentLevel,
    required this.currentLeague,
    required this.timeSpentByLanguage,
    required this.successRateByTheme,
  });

  final int totalXp;
  final int weeklyXp;
  final int streakCount;
  final int currentLevel;
  final String currentLeague;
  final List<LanguageTimeEntryModel> timeSpentByLanguage;
  final List<ThemeSuccessModel> successRateByTheme;

  factory AnalyticsDashboardModel.fromApi(Map<String, dynamic> json) {
    return AnalyticsDashboardModel(
      totalXp: json['total_xp'] as int? ?? 0,
      weeklyXp: json['weekly_xp'] as int? ?? 0,
      streakCount: json['streak_count'] as int? ?? 0,
      currentLevel: json['current_level'] as int? ?? 1,
      currentLeague: json['current_league'] as String? ?? 'bronze',
      timeSpentByLanguage: (json['time_spent_by_language'] as List<dynamic>? ?? [])
          .map((item) => LanguageTimeEntryModel.fromApi(item as Map<String, dynamic>))
          .toList(),
      successRateByTheme: (json['success_rate_by_theme'] as List<dynamic>? ?? [])
          .map((item) => ThemeSuccessModel.fromApi(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
