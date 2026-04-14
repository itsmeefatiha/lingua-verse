import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/learning_engine_models.dart';
import '../providers/learning_provider.dart';
import 'lesson_player_page.dart';

class CurrentLevelLessonsPage extends StatefulWidget {
  const CurrentLevelLessonsPage({super.key});

  @override
  State<CurrentLevelLessonsPage> createState() => _CurrentLevelLessonsPageState();
}

class _CurrentLevelLessonsPageState extends State<CurrentLevelLessonsPage> {
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) {
      return;
    }
    _bootstrapped = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final learning = context.read<LearningProvider>();
      final preferredLanguage = auth.user?.targetLanguage;
      await learning.fetchLanguages(preferredLanguageCode: preferredLanguage);

      final levels = learning.engineLevels;
      final userLevel = auth.user?.level ?? 1;
      final currentLevel = _resolveCurrentLevel(levels, userLevel);
      if (currentLevel != null) {
        await learning.fetchLessonsForLevel(currentLevel.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningProvider>();
    final auth = context.watch<AuthProvider>();
    final levels = learning.engineLevels;
    final userLevel = auth.user?.level ?? 1;
    final currentLevel = _resolveCurrentLevel(levels, userLevel);
    final lessons = currentLevel == null ? const <LearningLesson>[] : learning.lessonsForLevel(currentLevel.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Lessons')),
      body: RefreshIndicator(
        onRefresh: () async {
          await learning.fetchLevelsForLanguage();
          final refreshedCurrent = _resolveCurrentLevel(learning.engineLevels, userLevel);
          if (refreshedCurrent != null) {
            await learning.fetchLessonsForLevel(refreshedCurrent.id);
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (learning.error != null)
              Text(
                learning.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (currentLevel != null) ...[
              Text(
                'Current level: ${currentLevel.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
            ],
            if (learning.isLoadingCatalog && levels.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!learning.isLoadingCatalog && currentLevel == null)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: Text('No level found for your account yet.')),
              ),
            if (!learning.isLoadingCatalog && currentLevel != null && lessons.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('No lessons available for your current level yet.')),
              ),
            ...lessons.map(
              (lesson) => Card(
                child: ListTile(
                  title: Text(lesson.name),
                  subtitle: Text(lesson.isCompleted ? 'Completed' : 'In progress'),
                  trailing: Icon(lesson.isCompleted ? Icons.check_circle : Icons.play_circle_outline),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LessonPlayerPage(lesson: lesson),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LearningLevel? _resolveCurrentLevel(List<LearningLevel> levels, int userLevel) {
    if (levels.isEmpty) {
      return null;
    }

    final sorted = [...levels]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final explicit = sorted.where((level) => level.orderIndex == userLevel).toList();
    if (explicit.isNotEmpty) {
      return explicit.first;
    }

    final index = (userLevel - 1).clamp(0, sorted.length - 1);
    return sorted[index];
  }
}
