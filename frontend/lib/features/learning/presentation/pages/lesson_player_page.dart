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
            content: Text('Audio not available on this device. Showing text only.'),
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
        title: const Text('Great job!'),
        content: const Text('Lesson completed successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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

    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.name)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: words.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Word ${_index + 1} / ${words.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: _WordCard(
                      word: words[_index],
                      onSpeak: _speakCurrentWord,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _continue,
                    child: Text(_index == words.length - 1 ? 'Finish lesson' : 'Continue'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({required this.word, required this.onSpeak});

  final LearningWord word;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    word.targetText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Hear word',
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              word.nativeText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
