import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../../data/models/learning_engine_models.dart';
import '../providers/learning_provider.dart';

class LessonPlayerPage extends StatefulWidget {
  const LessonPlayerPage({super.key, required this.lesson});

  final LearningLesson lesson;

  @override
  State<LessonPlayerPage> createState() => _LessonPlayerPageState();
}

class _LessonPlayerPageState extends State<LessonPlayerPage> {
  FlutterTts? _tts;
  int _index = 0;
  bool _ttsMuted = false;

  FlutterTts _getTts() {
    if (_tts == null && !kIsWeb) {
      _tts = FlutterTts();
    }
    return _tts ?? FlutterTts();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final learning = context.read<LearningProvider>();
      await learning.fetchWordsForLesson(widget.lesson.id);
      if (!mounted) {
        return;
      }
      await _speakCurrentWord();
    });
  }

  @override
  void dispose() {
    if (!kIsWeb && _tts != null) {
      try {
        _tts?.stop();
      } catch (_) {
        // TTS not supported on this platform
      }
    }
    super.dispose();
  }

  Future<void> _speakCurrentWord() async {
    if (kIsWeb) {
      return;
    }

    final learning = context.read<LearningProvider>();
    final words = learning.wordsForLesson(widget.lesson.id);
    if (words.isEmpty || _index >= words.length) {
      return;
    }

    if (_ttsMuted) {
      return;
    }

    final languageCode = learning.activeLanguageCode ?? 'en';
    try {
      final tts = _getTts();
      await tts.setLanguage(languageCode);
      await tts.setSpeechRate(0.45);
      await tts.speak(words[_index].targetText);
    } catch (e) {
      // TTS failed (web platform or other issue), mute and continue with visual only
      if (mounted) {
        setState(() {
          _ttsMuted = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Audio not available on this device. Showing text only.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _continue() async {
    final learning = context.read<LearningProvider>();
    final words = learning.wordsForLesson(widget.lesson.id);
    if (words.isEmpty) {
      return;
    }

    if (_index < words.length - 1) {
      setState(() {
        _index += 1;
      });
      await _speakCurrentWord();
      return;
    }

    await learning.markLessonComplete(widget.lesson);
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Great job!'),
        content: const Text('Lesson completed successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningProvider>();
    final words = learning.wordsForLesson(widget.lesson.id);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lesson.name,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: words.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modern Pill Badge for Progress
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        'Word ${_index + 1} of ${words.length}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Animated Card Transition
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _WordCard(
                        key: ValueKey<int>(_index), // Crucial for animation
                        word: words[_index],
                        onSpeak: _speakCurrentWord,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Taller, premium action button
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _continue,
                      child: Text(
                        _index == words.length - 1 ? 'Finish lesson' : 'Continue',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12), // Safe area buffer
                ],
              ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({super.key, required this.word, required this.onSpeak});

  final LearningWord word;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final imageUrl = word.imageUrl?.trim() ?? '';
    final hasImage = imageUrl.isNotEmpty;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    word.targetText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    tooltip: 'Hear word',
                    onPressed: onSpeak,
                    icon: Icon(
                      Icons.volume_up_rounded,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 220,
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                child: hasImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _WordImagePlaceholder(label: word.targetText),
                      )
                    : _WordImagePlaceholder(label: word.targetText),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              word.nativeText,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordImagePlaceholder extends StatelessWidget {
  const _WordImagePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            color: scheme.onSurfaceVariant.withOpacity(0.5),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No image for "$label" yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}