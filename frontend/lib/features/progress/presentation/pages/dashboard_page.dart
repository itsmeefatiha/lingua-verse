import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shell/presentation/providers/shell_provider.dart';
import '../providers/progress_provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final auth = context.watch<AuthProvider>();
    final levels = progress.overview?.levels ?? const [];
    final overview = progress.overview;
    final analytics = progress.analytics;

    final fullName = auth.user?.fullName.trim() ?? '';
    final firstName = fullName.isEmpty ? 'Learner' : fullName.split(' ').first;
    final targetLanguage = auth.user?.targetLanguage.trim().toUpperCase();
    final languageLabel = (targetLanguage == null || targetLanguage.isEmpty)
        ? 'your language'
        : targetLanguage;

    if (progress.isLoading && levels.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final completionPercent = (overview?.overallCompletionPercent ?? 0).round();
    final completedLessons = overview?.completedLessons ?? 0;
    final totalLessons = overview?.totalLessons ?? 0;

    final successRates = [...(analytics?.successRateByTheme ?? const [])]
      ..sort((a, b) => b.successRate.compareTo(a.successRate));

    final averageQuizRate = successRates.isEmpty
        ? 0.0
        : successRates.map((e) => e.successRate).reduce((a, b) => a + b) /
              successRates.length;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome $firstName to LinguaVerse!',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Track your progress, keep learning, and review your quiz performance.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          if (progress.error != null) ...[
            const SizedBox(height: 8),
            Text(
              progress.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress in $languageLabel',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: completionPercent / 100,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$completionPercent% completed • $completedLessons/$totalLessons lessons',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.read<ShellProvider>().setIndex(1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 34,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Continue learning',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz Results',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  if (successRates.isEmpty)
                    Text(
                      'No quiz results available yet. Complete quizzes to see your stats.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else ...[
                    Text(
                      'Average score: ${averageQuizRate.round()}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...successRates
                        .take(3)
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.theme,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  '${item.successRate.round()}%',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (levels.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('No progress data available yet.')),
            ),
          _LevelProgressLineChart(levels: levels),
        ],
      ),
    );
  }
}

class _LevelProgressLineChart extends StatelessWidget {
  const _LevelProgressLineChart({required this.levels});

  final List<dynamic> levels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: CustomPaint(
            painter: _LevelProgressPainter(
              levels: levels,
              lineColor: scheme.primary,
              labelColor: scheme.onSurface,
            ),
            child: Container(),
          ),
        ),
      ),
    );
  }
}

class _LevelProgressPainter extends CustomPainter {
  _LevelProgressPainter({
    required this.levels,
    required this.lineColor,
    required this.labelColor,
  });

  final List<dynamic> levels;
  final Color lineColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) {
      return;
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final labelStyle = TextStyle(
      color: labelColor,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    final points = <Offset>[];
    final chartTop = 24.0;
    final chartBottom = size.height - 36;
    final chartHeight = chartBottom - chartTop;
    final stepX = levels.length == 1 ? 0.0 : size.width / (levels.length - 1);

    for (var index = 0; index < levels.length; index++) {
      final level = levels[index];
      final percent = (level.progressPercent as num).toDouble().clamp(
        0.0,
        100.0,
      );
      final x = levels.length == 1 ? size.width / 2 : stepX * index;
      final y = chartBottom - (chartHeight * (percent / 100));
      points.add(Offset(x, y));
    }

    for (var index = 0; index < points.length - 1; index++) {
      canvas.drawLine(points[index], points[index + 1], linePaint);
    }

    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      canvas.drawCircle(point, 5.5, dotPaint);

      final level = levels[index];
      final percent = (level.progressPercent as num).toDouble().round();
      final textSpan = TextSpan(
        text: '${level.levelCode} $percent%',
        style: labelStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(point.dx - textPainter.width / 2, point.dy - 26),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LevelProgressPainter oldDelegate) {
    return oldDelegate.levels != levels;
  }
}
