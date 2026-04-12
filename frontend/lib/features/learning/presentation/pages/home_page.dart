import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/catalog_models.dart';
import '../providers/learning_provider.dart';
import 'lesson_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningProvider>();
    final levels = learning.levels;

    if (learning.isLoadingCatalog && levels.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('Learning Roadmap', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Progress through CEFR levels from A1 to C2.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (learning.error != null) ...[
            const SizedBox(height: 8),
            Text(
              learning.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: levels.length,
              separatorBuilder: (_, separatorIndex) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final level = levels[index];
                return _LevelChip(level: level);
              },
            ),
          ),
          const SizedBox(height: 18),
          if (levels.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('No lessons found for now.')),
            ),
          ...levels.expand(
            (level) => level.lessons.map(
              (lesson) => _LessonTile(
                lesson: lesson,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LessonDetailPage(lesson: lesson),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final LevelModel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF00C7BE), Color(0xFF43E3D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            level.code,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            level.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.onTap});

  final LessonModel lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        title: Text(lesson.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(lesson.description),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: lesson.progress,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
