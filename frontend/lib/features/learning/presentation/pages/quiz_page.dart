import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/quiz_models.dart';
import '../providers/learning_provider.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with SingleTickerProviderStateMixin {
  int _index = 0;
  final Map<int, String> _answers = {};
  late final AnimationController _micController;
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _micController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _stopwatch = Stopwatch()..start();
  }

  @override
  void dispose() {
    _micController.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = context.watch<LearningProvider>().quizQuestions;
    final question = questions[_index];

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz ${_index + 1}/${questions.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(question.text, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Expanded(child: _buildQuestionInput(question)),
            FilledButton(
              onPressed: () async {
                final learningProvider = context.read<LearningProvider>();
                final messenger = ScaffoldMessenger.of(context);
                final answer = _answers[question.id] ?? '';
                if (answer.trim().isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Please provide an answer first.')),
                  );
                  return;
                }
                final result = await learningProvider.submitQuiz(
                      levelCode: null,
                      durationSeconds: _stopwatch.elapsed.inSeconds,
                      answers: {question.id: answer},
                    );
                if (!context.mounted) {
                  return;
                }
                final feedback = result?.feedback.firstWhere(
                  (item) => item.questionId == question.id,
                  orElse: () => const AnswerFeedbackModel(
                    questionId: 0,
                    isCorrect: false,
                    correctAnswer: '',
                    explanation: 'No feedback available.',
                  ),
                );
                if (feedback == null) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Failed to validate answer with server.')),
                  );
                  return;
                }
                _showFeedback(
                  context,
                  isCorrect: feedback.isCorrect,
                  explanation: feedback.explanation,
                );
              },
              child: const Text('Validate answer'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                if (_index < questions.length - 1) {
                  setState(() => _index++);
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Text(_index < questions.length - 1 ? 'Next question' : 'Finish'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput(QuizQuestionModel question) {
    switch (question.type) {
      case QuizQuestionType.multipleChoice:
        return ListView.separated(
          itemCount: question.choices.length,
          separatorBuilder: (_, separatorIndex) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final choice = question.choices[index];
            final selected = _answers[question.id] == choice;
            return GestureDetector(
              onTap: () => setState(() => _answers[question.id] = choice),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                  ),
                ),
                child: Text(choice),
              ),
            );
          },
        );
      case QuizQuestionType.fillBlank:
        return TextField(
          decoration: const InputDecoration(
            hintText: 'Type your answer',
            prefixIcon: Icon(Icons.edit_outlined),
          ),
          onChanged: (value) => _answers[question.id] = value,
        );
      case QuizQuestionType.reorder:
        return _ReorderBuilder(
          words: question.choices,
          onResult: (value) => _answers[question.id] = value,
        );
      case QuizQuestionType.speech:
        return _SpeechPracticeCard(
          controller: _micController,
          onRecognizedText: (value) => _answers[question.id] = value,
        );
    }
  }

  void _showFeedback(
    BuildContext context, {
    required bool isCorrect,
    required String explanation,
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierLabel: 'feedback',
      barrierDismissible: true,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isCorrect ? const Color(0xFF2DBE7F) : const Color(0xFFE84B5F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.error_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isCorrect ? 'Correct answer' : 'Needs improvement',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    explanation,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpeechPracticeCard extends StatefulWidget {
  const _SpeechPracticeCard({
    required this.controller,
    required this.onRecognizedText,
  });

  final AnimationController controller;
  final ValueChanged<String> onRecognizedText;

  @override
  State<_SpeechPracticeCard> createState() => _SpeechPracticeCardState();
}

class _SpeechPracticeCardState extends State<_SpeechPracticeCard> {
  String _mockTranscript = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Speech-to-Text practice'),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: widget.controller,
              builder: (context, child) {
                final pulse = 1 + (widget.controller.value * 0.25);
                return Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      iconSize: 42,
                      onPressed: () {
                        setState(() {
                          _mockTranscript = 'I am ready to begin';
                        });
                        widget.onRecognizedText(_mockTranscript);
                      },
                      icon: const Icon(Icons.mic_rounded),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Text(
              _mockTranscript.isEmpty
                  ? 'Tap microphone to simulate speech input.'
                  : 'Transcript: $_mockTranscript',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReorderBuilder extends StatefulWidget {
  const _ReorderBuilder({required this.words, required this.onResult});

  final List<String> words;
  final ValueChanged<String> onResult;

  @override
  State<_ReorderBuilder> createState() => _ReorderBuilderState();
}

class _ReorderBuilderState extends State<_ReorderBuilder> {
  late List<String> _words;

  @override
  void initState() {
    super.initState();
    _words = widget.words.toList();
    _words.shuffle(math.Random());
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      itemCount: _words.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = _words.removeAt(oldIndex);
          _words.insert(newIndex, item);
        });
        widget.onResult(_words.join(' ').trim());
      },
      itemBuilder: (context, index) {
        final word = _words[index];
        return Card(
          key: ValueKey(word),
          child: ListTile(
            title: Text(word),
            trailing: const Icon(Icons.drag_indicator_rounded),
          ),
        );
      },
    );
  }
}
