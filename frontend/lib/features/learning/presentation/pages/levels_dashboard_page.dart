import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/learning_engine_models.dart';
import '../providers/learning_provider.dart';
import 'lesson_player_page.dart';
import 'level_quiz_page.dart';

class LevelsDashboardPage extends StatefulWidget {
  const LevelsDashboardPage({super.key});

  @override
  State<LevelsDashboardPage> createState() => _LevelsDashboardPageState();
}

class _LevelsDashboardPageState extends State<LevelsDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetLanguage = context.read<AuthProvider>().user?.targetLanguage;
      context.read<LearningProvider>().fetchLanguages(
        preferredLanguageCode: targetLanguage,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningProvider>();
    final levels = learning.engineLevels;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subdued = scheme.onSurface.withOpacity(0.75);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Your Journey',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00D1C1),
        onRefresh: () => learning.fetchLevelsForLanguage(),
        child: learning.isLoadingCatalog && levels.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00D1C1)),
              )
            : levels.isEmpty
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: Text('No levels available yet.')),
                  ),
                ],
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  // The Stack holds the drawn path on the bottom, and the interactive nodes on top
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // 1. The Winding Road Background
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _RoadPathPainter(
                            count: levels.length,
                            itemHeight: 160.0,
                          ),
                        ),
                      ),
                      // 2. The Level Nodes
                      Column(
                        children: levels.asMap().entries.map((entry) {
                          final index = entry.key;
                          final level = entry.value;
                          return _buildLevelNode(
                            context,
                            level,
                            index,
                            learning,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLevelNode(
    BuildContext context,
    LearningLevel level,
    int index,
    LearningProvider learning,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final subdued = scheme.onSurface.withOpacity(0.75);

    final isLocked = learning.isLevelLocked(level);
    final isCompleted = level.isCompleted;
    final isActive = !isLocked && !isCompleted;

    // Shift the node left or right based on the index to sit on the curve
    final offsetX = _RoadPathPainter.getOffsetX(index);

    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Center(
        child: Transform.translate(
          offset: Offset(offsetX, 0),
          child: GestureDetector(
            onTap: isLocked
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Complete previous levels to unlock!'),
                    ),
                  )
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _LevelLessonsPage(level: level),
                      ),
                    );
                  },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "Start Here" floating badge for the active level
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: subdued,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'START HERE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // The Circular Node
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLocked
                        ? const Color(0xFFF0F0F0) // Grey for locked
                        : isActive
                        ? const Color(0xFF00D1C1) // Vibrant Teal for active
                        : const Color(0xFFB2EBF2), // Light teal for completed
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF00BFA5)
                          : Colors.transparent,
                      width: isActive ? 4 : 0,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00D1C1).withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    isLocked
                        ? Icons.lock_rounded
                        : isCompleted
                        ? Icons.check_rounded
                        : Icons.play_arrow_rounded,
                    color: isLocked
                        ? Colors.black26
                        : isActive
                        ? Colors.white
                        : const Color(0xFF00796B), // Darker teal checkmark
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),

                // Level Name Text
                Text(
                  level.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isLocked
                        ? subdued.withOpacity(0.6)
                        : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- CUSTOM PAINTER FOR THE WINDING ROAD ---
class _RoadPathPainter extends CustomPainter {
  final int count;
  final double itemHeight;

  _RoadPathPainter({required this.count, required this.itemHeight});

  // Determines how far left or right the path swings based on the row index
  static double getOffsetX(int index) {
    int mod = index % 4;
    if (mod == 0) return 0; // Center
    if (mod == 1) return 70; // Right
    if (mod == 2) return 0; // Center
    return -70; // Left
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 1) return;

    final paint = Paint()
      ..color =
          const Color(0xFFE0F2F1) // Very light teal background path
      ..strokeWidth =
          28 // Thick road
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;

    // Start at the center of the first item
    path.moveTo(w / 2 + getOffsetX(0), itemHeight / 2);

    for (int i = 1; i < count; i++) {
      final prevY = (i - 1) * itemHeight + (itemHeight / 2);
      final prevX = w / 2 + getOffsetX(i - 1);

      final currentY = i * itemHeight + (itemHeight / 2);
      final currentX = w / 2 + getOffsetX(i);

      // Draw a smooth S-curve bezier between the previous node and the current node
      path.cubicTo(
        prevX,
        prevY + itemHeight / 2.5, // Control point 1 (pulls down from prev)
        currentX,
        currentY - itemHeight / 2.5, // Control point 2 (pulls up from current)
        currentX,
        currentY,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- LESSONS PAGE STYLING ---
class _LevelLessonsPage extends StatefulWidget {
  const _LevelLessonsPage({required this.level});

  final LearningLevel level;

  @override
  State<_LevelLessonsPage> createState() => _LevelLessonsPageState();
}

class _LevelLessonsPageState extends State<_LevelLessonsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LearningProvider>().fetchLessonsForLevel(widget.level.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningProvider>();
    final lessons = learning.lessonsForLevel(widget.level.id);
    final allLessonsDone =
        lessons.isNotEmpty && lessons.every((lesson) => lesson.isCompleted);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor = theme.dividerColor.withOpacity(0.5);
    final subdued = scheme.onSurface.withOpacity(0.75);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          '${widget.level.name} Lessons',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...lessons.map(
            (lesson) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border.all(
                  color: lesson.isCompleted ? scheme.primary : borderColor,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                title: Text(
                  lesson.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  lesson.isCompleted ? 'Completed' : 'In progress',
                  style: TextStyle(
                    color: lesson.isCompleted ? scheme.primary : subdued,
                  ),
                ),
                trailing: Icon(
                  lesson.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.play_circle_fill_rounded,
                  color: lesson.isCompleted
                      ? scheme.primary
                      : subdued.withOpacity(0.5),
                  size: 32,
                ),
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
          const SizedBox(height: 24),
          if (allLessonsDone)
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LevelQuizPage(level: widget.level),
                    ),
                  );
                },
                icon: const Icon(Icons.star_rounded, color: Colors.white),
                label: const Text(
                  'Take Level Quiz',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D1C1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
