enum QuizQuestionType { multipleChoice, fillBlank, reorder, speech }

class QuizQuestionModel {
  const QuizQuestionModel({
    required this.id,
    required this.type,
    required this.text,
    required this.choices,
    required this.correctAnswer,
    required this.explanation,
  });

  final int id;
  final QuizQuestionType type;
  final String text;
  final List<String> choices;
  final String correctAnswer;
  final String explanation;

  factory QuizQuestionModel.fromApi(Map<String, dynamic> json) {
    final typeValue = (json['question_type'] as String? ?? 'qcm');
    return QuizQuestionModel(
      id: json['id'] as int,
      type: _fromApiType(typeValue),
      text: json['text'] as String? ?? '',
      choices: _buildChoices(json),
      correctAnswer: json['correct_answer'] as String? ?? '',
      explanation: json['grammatical_explanation'] as String? ?? '',
    );
  }

  static List<String> _buildChoices(Map<String, dynamic> json) {
    // First check if choices are directly provided
    final direct = json['choices'];
    if (direct is List<dynamic>) {
      return direct.map((item) => item.toString()).toList();
    }
    // Fallback: extract from text
    final text = json['text'] as String? ?? '';
    final matches = RegExp(r'\[(.*?)\]').allMatches(text);
    return matches.map((m) => m.group(1) ?? '').where((v) => v.isNotEmpty).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_type': _toApiType(type),
      'text': text,
      'choices': choices,
      'correct_answer': correctAnswer,
      'grammatical_explanation': explanation,
    };
  }

  static QuizQuestionType _fromApiType(String value) {
    switch (value) {
      case 'gap_text':
        return QuizQuestionType.fillBlank;
      case 'ordering':
        return QuizQuestionType.reorder;
      case 'voice':
        return QuizQuestionType.speech;
      default:
        return QuizQuestionType.multipleChoice;
    }
  }

  static String _toApiType(QuizQuestionType type) {
    switch (type) {
      case QuizQuestionType.fillBlank:
        return 'gap_text';
      case QuizQuestionType.reorder:
        return 'ordering';
      case QuizQuestionType.speech:
        return 'voice';
      case QuizQuestionType.multipleChoice:
        return 'qcm';
    }
  }
}

class AnswerFeedbackModel {
  const AnswerFeedbackModel({
    required this.questionId,
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
  });

  final int questionId;
  final bool isCorrect;
  final String correctAnswer;
  final String explanation;

  factory AnswerFeedbackModel.fromApi(Map<String, dynamic> json) {
    return AnswerFeedbackModel(
      questionId: json['question_id'] as int,
      isCorrect: json['is_correct'] as bool? ?? false,
      correctAnswer: json['correct_answer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

class QuizSubmitResponseModel {
  const QuizSubmitResponseModel({
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.feedback,
  });

  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final List<AnswerFeedbackModel> feedback;

  factory QuizSubmitResponseModel.fromApi(Map<String, dynamic> json) {
    return QuizSubmitResponseModel(
      score: json['score'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      correctAnswers: json['correct_answers'] as int? ?? 0,
      feedback: (json['feedback'] as List<dynamic>? ?? [])
          .map((item) => AnswerFeedbackModel.fromApi(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizAttemptModel {
  const QuizAttemptModel({
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.languageCode,
    required this.durationSeconds,
    required this.levelCode,
    required this.attemptedAt,
    required this.submittedAnswers,
  });

  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final String? languageCode;
  final int? durationSeconds;
  final String? levelCode;
  final DateTime attemptedAt;
  final List<Map<String, dynamic>> submittedAnswers;

  factory QuizAttemptModel.fromApi(Map<String, dynamic> json) {
    return QuizAttemptModel(
      score: json['score'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      correctAnswers: json['correct_answers'] as int? ?? 0,
      languageCode: (json['language_code'] as String?)?.trim(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      levelCode: (json['level_code'] as String?)?.trim(),
      attemptedAt: DateTime.tryParse(json['attempted_at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      submittedAnswers: (json['submitted_answers'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
    );
  }

  List<int> get wrongQuestionIds {
    return submittedAnswers
        .where((entry) => entry['is_correct'] == false)
        .map((entry) => (entry['question_id'] as num?)?.toInt())
        .whereType<int>()
        .toList();
  }
}
