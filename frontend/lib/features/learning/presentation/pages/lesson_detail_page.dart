import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/catalog_models.dart';
import '../providers/learning_provider.dart';
import '../widgets/vocabulary_card.dart';
import 'quiz_page.dart';

class LessonDetailPage extends StatelessWidget {
  const LessonDetailPage({super.key, required this.lesson});

  final LessonModel lesson;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final learning = context.read<LearningProvider>();
                        await learning.loadQuiz(levelCode: lesson.levelCode, count: 10);
                        if (!context.mounted) {
                          return;
                        }
                        if (learning.quizQuestions.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(learning.error ?? 'No quiz questions available.')),
                          );
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const QuizPage()),
                        );
                      },
                      icon: const Icon(Icons.quiz_outlined),
                      label: const Text('Start quiz'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...lesson.vocabularies.map(
            (vocabulary) => VocabularyCard(
              vocabulary: vocabulary,
              onAudioTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Audio trigger ready for "${vocabulary.term}"'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
