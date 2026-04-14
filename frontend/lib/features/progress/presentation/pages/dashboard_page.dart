import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/progress_provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final levels = progress.overview?.levels ?? const [];

    if (progress.isLoading && levels.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Home Progress', style: Theme.of(context).textTheme.headlineSmall),
          if (progress.error != null) ...[
            const SizedBox(height: 8),
            Text(
              progress.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          if (levels.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('No progress data available yet.')),
            ),
          _LevelProgressLineChart(levels: levels),
          const SizedBox(height: 16),
          _LevelProgressLegend(levels: levels),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overall', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (progress.overview?.overallCompletionPercent ?? 0) / 100,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 10),
                  Text('${(progress.overview?.overallCompletionPercent ?? 0).round()}% completed'),
                ],
              ),
            ),
          ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: CustomPaint(
            painter: _LevelProgressPainter(levels: levels),
            child: Container(),
          ),
        ),
      ),
    );
  }
}

class _LevelProgressLegend extends StatelessWidget {
  const _LevelProgressLegend({required this.levels});

  final List<dynamic> levels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: levels
          .map(
            (level) => Chip(
              avatar: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  (level.levelName as String).toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              label: Text('${level.progressPercent.round()}%'),
            ),
          )
          .toList(),
    );
  }
}

class _LevelProgressPainter extends CustomPainter {
  _LevelProgressPainter({required this.levels});

  final List<dynamic> levels;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) {
      return;
    }

    final linePaint = Paint()
      ..color = const Color(0xFF00D1C1)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = const Color(0xFF00D1C1)
      ..style = PaintingStyle.fill;

    final labelStyle = const TextStyle(
      color: Colors.black87,
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
      final percent = (level.progressPercent as num).toDouble().clamp(0.0, 100.0);
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
      final textSpan = TextSpan(text: '${level.levelCode} $percent%', style: labelStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(point.dx - textPainter.width / 2, point.dy - 26));
    }
  }

  @override
  bool shouldRepaint(covariant _LevelProgressPainter oldDelegate) {
    return oldDelegate.levels != levels;
  }
}
