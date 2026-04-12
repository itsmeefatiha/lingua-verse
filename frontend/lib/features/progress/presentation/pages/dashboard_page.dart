import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/progress_provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final lessons = progress.overview?.lessons ?? const [];

    if (progress.isLoading && lessons.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Progress Dashboard', style: Theme.of(context).textTheme.headlineSmall),
          if (progress.error != null) ...[
            const SizedBox(height: 8),
            Text(
              progress.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          if (lessons.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('No progress data available yet.')),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: lessons
                .map(
                  (lesson) => SizedBox(
                    width: 165,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CircularProgressIndicator(
                                    value: lesson.progressPercent / 100,
                                    strokeWidth: 9,
                                  ),
                                  Center(
                                    child: Text('${lesson.progressPercent.round()}%'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              lesson.lessonTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
