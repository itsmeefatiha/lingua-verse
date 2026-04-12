enum CefrLevel { a1, a2, b1, b2, c1, c2 }

String levelTitleFromCode(String code) {
  switch (code.toUpperCase()) {
    case 'A1':
      return 'Beginner Foundations';
    case 'A2':
      return 'Elementary Communication';
    case 'B1':
      return 'Independent User';
    case 'B2':
      return 'Upper Intermediate';
    case 'C1':
      return 'Advanced Fluency';
    case 'C2':
      return 'Mastery';
    default:
      return 'Level';
  }
}

class LevelModel {
  const LevelModel({
    required this.id,
    required this.code,
    required this.displayOrder,
    required this.lessons,
  });

  final int id;
  final String code;
  final int displayOrder;
  final List<LessonModel> lessons;

  String get title => levelTitleFromCode(code);

  factory LevelModel.fromApi(Map<String, dynamic> json) {
    return LevelModel(
      id: json['id'] as int,
      code: json['code'] as String,
      displayOrder: json['display_order'] as int? ?? 0,
      lessons: const [],
    );
  }

  LevelModel copyWith({List<LessonModel>? lessons}) {
    return LevelModel(
      id: id,
      code: code,
      displayOrder: displayOrder,
      lessons: lessons ?? this.lessons,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'display_order': displayOrder,
      'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
    };
  }
}

class LessonModel {
  const LessonModel({
    required this.id,
    required this.levelId,
    required this.levelCode,
    required this.displayOrder,
    required this.title,
    required this.description,
    required this.progress,
    required this.vocabularies,
  });

  final int id;
  final int levelId;
  final String levelCode;
  final int displayOrder;
  final String title;
  final String description;
  final double progress;
  final List<VocabularyModel> vocabularies;

  factory LessonModel.fromApi(Map<String, dynamic> json, String levelCode) {
    return LessonModel(
      id: json['id'] as int,
      levelId: json['level_id'] as int,
      levelCode: levelCode,
      displayOrder: json['display_order'] as int? ?? 0,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      vocabularies: const [],
    );
  }

  LessonModel copyWith({double? progress, List<VocabularyModel>? vocabularies}) {
    return LessonModel(
      id: id,
      levelId: levelId,
      levelCode: levelCode,
      displayOrder: displayOrder,
      title: title,
      description: description,
      progress: progress ?? this.progress,
      vocabularies: vocabularies ?? this.vocabularies,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level_id': levelId,
      'level_code': levelCode,
      'display_order': displayOrder,
      'title': title,
      'description': description,
      'progress': progress,
      'vocabularies': vocabularies.map((v) => v.toJson()).toList(),
    };
  }
}

class VocabularyModel {
  const VocabularyModel({
    required this.id,
    required this.term,
    required this.translation,
    required this.example,
    required this.category,
  });

  final int id;
  final String term;
  final String translation;
  final String example;
  final String category;

  factory VocabularyModel.fromApi(Map<String, dynamic> json) {
    return VocabularyModel(
      id: json['id'] as int,
      term: json['term'] as String,
      translation: json['translation'] as String,
      example: json['example'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'term': term,
      'translation': translation,
      'example': example,
      'category': category,
    };
  }
}
