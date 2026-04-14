class LearningLanguage {
  const LearningLanguage({
    required this.id,
    required this.name,
    required this.code,
  });

  final int id;
  final String name;
  final String code;

  factory LearningLanguage.fromApi(Map<String, dynamic> json) {
    final code = (json['code'] as String? ?? '').trim().toLowerCase();
    return LearningLanguage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : _languageNameFromCode(code),
      code: code,
    );
  }

  static String _languageNameFromCode(String code) {
    switch (code) {
      case 'fr':
        return 'French';
      case 'en':
        return 'English';
      case 'es':
        return 'Spanish';
      case 'de':
        return 'German';
      case 'ar':
        return 'Arabic';
      case 'it':
        return 'Italian';
      case 'pt':
        return 'Portuguese';
      default:
        return code.toUpperCase();
    }
  }
}

class LearningLevel {
  const LearningLevel({
    required this.id,
    required this.languageId,
    required this.name,
    required this.orderIndex,
    required this.isCompleted,
    required this.isLocked,
  });

  final int id;
  final int languageId;
  final String name;
  final int orderIndex;
  final bool isCompleted;
  final bool isLocked;

  factory LearningLevel.fromApi(
    Map<String, dynamic> json, {
    required int fallbackLanguageId,
  }) {
    return LearningLevel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      languageId: (json['language_id'] as num?)?.toInt() ?? fallbackLanguageId,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : (json['code'] as String? ?? '').trim().toUpperCase(),
      orderIndex: (json['order_index'] as num?)?.toInt() ?? (json['display_order'] as num?)?.toInt() ?? 0,
      isCompleted: (json['is_completed'] as bool?) ?? false,
      isLocked: (json['is_locked'] as bool?) ?? true,
    );
  }

  LearningLevel copyWith({
    bool? isCompleted,
    bool? isLocked,
  }) {
    return LearningLevel(
      id: id,
      languageId: languageId,
      name: name,
      orderIndex: orderIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

class LearningLesson {
  const LearningLesson({
    required this.id,
    required this.levelId,
    required this.name,
    required this.orderIndex,
    required this.isCompleted,
  });

  final int id;
  final int levelId;
  final String name;
  final int orderIndex;
  final bool isCompleted;

  factory LearningLesson.fromApi(Map<String, dynamic> json) {
    final progress = (json['progress'] as num?)?.toDouble() ?? 0;
    return LearningLesson(
      id: (json['id'] as num?)?.toInt() ?? 0,
      levelId: (json['level_id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : (json['title'] as String? ?? 'Lesson'),
      orderIndex: (json['order_index'] as num?)?.toInt() ?? (json['display_order'] as num?)?.toInt() ?? 0,
      isCompleted: (json['is_completed'] as bool?) ?? progress >= 1,
    );
  }

  LearningLesson copyWith({bool? isCompleted}) {
    return LearningLesson(
      id: id,
      levelId: levelId,
      name: name,
      orderIndex: orderIndex,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class LearningWord {
  const LearningWord({
    required this.id,
    required this.lessonId,
    required this.nativeText,
    required this.targetText,
  });

  final int id;
  final int lessonId;
  final String nativeText;
  final String targetText;

  factory LearningWord.fromApi(Map<String, dynamic> json) {
    return LearningWord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      lessonId: (json['lesson_id'] as num?)?.toInt() ?? 0,
      nativeText: (json['native_text'] as String?)?.trim().isNotEmpty == true
          ? (json['native_text'] as String).trim()
          : (json['translation'] as String? ?? ''),
      targetText: (json['target_text'] as String?)?.trim().isNotEmpty == true
          ? (json['target_text'] as String).trim()
          : (json['term'] as String? ?? ''),
    );
  }
}
