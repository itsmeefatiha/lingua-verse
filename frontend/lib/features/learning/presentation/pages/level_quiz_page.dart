import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/learning_engine_models.dart';
import '../../data/models/quiz_models.dart';
import '../providers/learning_provider.dart';

class LevelQuizPage extends StatefulWidget {
  const LevelQuizPage({super.key, required this.level});

  final LearningLevel level;

  @override
  State<LevelQuizPage> createState() => _LevelQuizPageState();
}

class _LevelQuizPageState extends State<LevelQuizPage> {
  final Map<int, String> _answers = {};
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;
  int? _listeningQuestionId;
  bool _loadingPreviousWrongAnswers = true;

  static const Map<String, String> _languageLocaleIds = {
    'en': 'en_US',
    'fr': 'fr_FR',
    'es': 'es_ES',
    'de': 'de_DE',
    'ar': 'ar_SA',
    'it': 'it_IT',
    'pt': 'pt_PT',
    'zh': 'zh_CN',
    'ja': 'ja_JP',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final auth = context.read<AuthProvider>();
        final languageCode = auth.user?.targetLanguage.trim().toLowerCase();
        await context.read<LearningProvider>().loadQuiz(
              levelCode: widget.level.name,
              languageCode: languageCode,
              count: 8,
            );
        await context.read<LearningProvider>().loadPreviousWrongAnswers(levelCode: widget.level.name);
        if (!mounted) {
          return;
        }
        _speechReady = await _speechToText.initialize(
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              if (mounted) {
                setState(() {
                  _isListening = false;
                  _listeningQuestionId = null;
                });
              }
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isListening = false;
                _listeningQuestionId = null;
              });
            }
          },
        );
        if (mounted) {
          setState(() {});
        }
      } finally {
        if (mounted) {
          setState(() {
            _loadingPreviousWrongAnswers = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }

  Future<void> _submit() async {
    final learning = context.read<LearningProvider>();
    final questions = learning.quizQuestions;
    if (questions.isEmpty || _answers.length != questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer all questions first.')),
      );
      return;
    }

    final response = await learning.submitLevelQuiz(
      levelId: widget.level.id,
      answers: _answers,
      durationSeconds: 120,
    );

    final passed = (response?.score ?? 0) >= 80;

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(passed ? 'Level unlocked' : 'Try again'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              passed
                  ? 'Quiz passed. The next level is now unlocked.'
                  : 'Quiz not passed yet. You need at least 80%.',
            ),
            const SizedBox(height: 8),
            Text('Score: ${(response?.score ?? 0).toStringAsFixed(0)}/100'),
            Text('Correct answers: ${response?.correctAnswers ?? 0}/${response?.totalQuestions ?? questions.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (mounted && passed) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _startListening(QuizQuestionModel question) async {
    if (!_speechReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not available on this device.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final localeId = _languageLocaleIds[auth.user?.targetLanguage.trim().toLowerCase() ?? 'en'] ?? 'en_US';

    await _speechToText.stop();
    setState(() {
      _listeningQuestionId = question.id;
      _isListening = true;
    });

    await _speechToText.listen(
      localeId: localeId,
      listenMode: stt.ListenMode.confirmation,
      partialResults: true,
      onResult: (result) {
        setState(() {
          _answers[question.id] = result.recognizedWords;
        });
        if (result.finalResult) {
          _speechToText.stop();
          if (mounted) {
            setState(() {
              _isListening = false;
              _listeningQuestionId = null;
            });
          }
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _isListening = false;
      _listeningQuestionId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningProvider>();
    final questions = learning.quizQuestions;
    final wrongQuestionIds = learning.wrongQuestionIdsForLevel(widget.level.name);

    return Scaffold(
      appBar: AppBar(title: Text('${widget.level.name} Quiz')),
        body: (learning.isLoadingQuiz || _loadingPreviousWrongAnswers) && questions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (learning.error != null)
                  Text(
                    learning.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                const SizedBox(height: 4),
                if (questions.isNotEmpty)
                  Text(
                    'This quiz mixes translation and speaking questions from the current level only.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 12),
                ...questions.map(
                  (question) => _QuestionCard(
                    question: question,
                    selectedAnswer: _answers[question.id],
                    isPreviouslyWrong: wrongQuestionIds.contains(question.id),
                    isListening: _isListening && _listeningQuestionId == question.id,
                    speechReady: _speechReady,
                    onAnswer: (answer) {
                      setState(() {
                        _answers[question.id] = answer;
                      });
                    },
                    onSpeakTap: question.type == QuizQuestionType.speech
                        ? () => _startListening(question)
                        : null,
                    onStopSpeakTap: question.type == QuizQuestionType.speech
                        ? _stopListening
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: questions.isEmpty ? null : _submit,
                  child: const Text('Submit level quiz'),
                ),
              ],
            ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.selectedAnswer,
    required this.isPreviouslyWrong,
    required this.isListening,
    required this.speechReady,
    required this.onAnswer,
    required this.onSpeakTap,
    required this.onStopSpeakTap,
  });

  final QuizQuestionModel question;
  final String? selectedAnswer;
  final bool isPreviouslyWrong;
  final bool isListening;
  final bool speechReady;
  final ValueChanged<String> onAnswer;
  final VoidCallback? onSpeakTap;
  final VoidCallback? onStopSpeakTap;

  @override
  Widget build(BuildContext context) {
    final choices = question.choices.isEmpty ? <String>[question.correctAnswer] : question.choices;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isPreviouslyWrong ? scheme.errorContainer.withOpacity(0.35) : null,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isPreviouslyWrong ? scheme.error : theme.dividerColor,
          width: isPreviouslyWrong ? 1.4 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.text, style: theme.textTheme.titleMedium),
            if (isPreviouslyWrong) ...[
              const SizedBox(height: 6),
              Text(
                'Previously answered incorrectly',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            switch (question.type) {
              QuizQuestionType.multipleChoice => Column(
                  children: choices
                      .map(
                        (choice) => RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: choice,
                          groupValue: selectedAnswer,
                          onChanged: (value) {
                            if (value != null) {
                              onAnswer(value);
                            }
                          },
                          title: Text(choice),
                        ),
                      )
                      .toList(),
                ),
              QuizQuestionType.speech => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mic_none_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedAnswer == null || selectedAnswer!.trim().isEmpty
                                  ? (speechReady
                                      ? 'Tap the microphone and say the word aloud'
                                      : 'Speech recognition is not available')
                                  : selectedAnswer!.trim(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: speechReady
                                ? (isListening ? onStopSpeakTap : onSpeakTap)
                                : null,
                            icon: Icon(isListening ? Icons.stop_rounded : Icons.mic_rounded),
                            label: Text(isListening ? 'Stop listening' : 'Speak now'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedAnswer == null || selectedAnswer!.trim().isEmpty
                          ? 'No transcript yet.'
                          : 'Transcript: ${selectedAnswer!.trim()}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              _ => TextField(
                  decoration: const InputDecoration(
                    hintText: 'Type your answer',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  onChanged: (value) => onAnswer(value),
                ),
            },
          ],
        ),
      ),
    );
  }
}
