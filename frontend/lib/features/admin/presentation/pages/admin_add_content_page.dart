import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../learning/data/models/learning_engine_models.dart';
import '../../data/repositories/admin_repository.dart';

enum AdminAddContentType { level, lesson, word }

class AdminAddContentPage extends StatefulWidget {
  const AdminAddContentPage({
    super.key,
    required this.type,
  });

  final AdminAddContentType type;

  @override
  State<AdminAddContentPage> createState() => _AdminAddContentPageState();
}

class _AdminAddContentPageState extends State<AdminAddContentPage> {
  static const List<String> _cefrLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _displayOrderController = TextEditingController(text: '1');
  final _termController = TextEditingController();
  final _translationController = TextEditingController();
  final _categoryController = TextEditingController();
  final _exampleController = TextEditingController();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  List<LearningLanguage> _languages = const [];
  List<LearningLevel> _levels = const [];
  List<LearningLesson> _lessons = const [];

  LearningLanguage? _selectedLanguage;
  LearningLevel? _selectedLevel;
  LearningLesson? _selectedLesson;
  String _selectedLevelCode = 'A1';

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _displayOrderController.dispose();
    _termController.dispose();
    _translationController.dispose();
    _categoryController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<AdminRepository>();
      final languages = await repo.fetchLanguages();
      setState(() {
        _languages = languages;
        _selectedLanguage = languages.isNotEmpty ? languages.first : null;
      });

      if (_selectedLanguage != null && widget.type != AdminAddContentType.level) {
        await _loadLevels(_selectedLanguage!.code);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLevels(String languageCode) async {
    if (_selectedLanguage == null) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<AdminRepository>();
      final levels = await repo.fetchLevelsForLanguage(
        languageCode,
        languageId: _selectedLanguage!.id,
      );
      setState(() {
        _levels = levels;
        _selectedLevel = levels.isNotEmpty ? levels.first : null;
      });

      if (_selectedLevel != null && widget.type == AdminAddContentType.word) {
        await _loadLessons(_selectedLevel!.id);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLessons(int levelId) async {
    if (_selectedLanguage == null || _selectedLevel == null) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<AdminRepository>();
      final lessons = await repo.fetchLessonsForLevel(
        levelId: levelId,
        levelName: _selectedLevel!.name,
        languageCode: _selectedLanguage!.code,
      );
      setState(() {
        _lessons = lessons;
        _selectedLesson = lessons.isNotEmpty ? lessons.first : null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final repo = context.read<AdminRepository>();
      switch (widget.type) {
        case AdminAddContentType.level:
          if (_selectedLanguage == null) {
            throw Exception('Please select a language.');
          }
          await repo.createLevel(
            languageId: _selectedLanguage!.id,
            levelCode: _selectedLevelCode,
            displayOrder: int.tryParse(_displayOrderController.text.trim()) ?? 1,
          );
          break;
        case AdminAddContentType.lesson:
          if (_selectedLevel == null) {
            throw Exception('Please select a level.');
          }
          await repo.createLesson(
            levelId: _selectedLevel!.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            displayOrder: int.tryParse(_displayOrderController.text.trim()) ?? 1,
          );
          break;
        case AdminAddContentType.word:
          if (_selectedLesson == null) {
            throw Exception('Please select a lesson.');
          }
          await repo.createWord(
            lessonId: _selectedLesson!.id,
            term: _termController.text.trim(),
            translation: _translationController.text.trim(),
            category: _categoryController.text.trim(),
            example: _exampleController.text.trim(),
          );
          break;
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String get _title {
    switch (widget.type) {
      case AdminAddContentType.level:
        return 'Add Level';
      case AdminAddContentType.lesson:
        return 'Add Lesson';
      case AdminAddContentType.word:
        return 'Add Word';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(_title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                      ),
                    _languageDropdown(),
                    if (widget.type == AdminAddContentType.level) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedLevelCode,
                        decoration: const InputDecoration(labelText: 'CEFR Level'),
                        items: _cefrLevels
                            .map((level) => DropdownMenuItem<String>(value: level, child: Text(level)))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _selectedLevelCode = value);
                        },
                      ),
                    ],
                    if (widget.type != AdminAddContentType.level) ...[
                      const SizedBox(height: 12),
                      _levelDropdown(),
                    ],
                    if (widget.type == AdminAddContentType.word) ...[
                      const SizedBox(height: 12),
                      _lessonDropdown(),
                    ],
                    if (widget.type == AdminAddContentType.lesson) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Lesson title'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description (optional)'),
                        minLines: 2,
                        maxLines: 3,
                      ),
                    ],
                    if (widget.type == AdminAddContentType.word) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _termController,
                        decoration: const InputDecoration(labelText: 'Target word'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _translationController,
                        decoration: const InputDecoration(labelText: 'Translation'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(labelText: 'Category (optional)'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _exampleController,
                        decoration: const InputDecoration(labelText: 'Example (optional)'),
                        minLines: 2,
                        maxLines: 3,
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _displayOrderController,
                      decoration: const InputDecoration(labelText: 'Display order'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed = int.tryParse((value ?? '').trim());
                        if (parsed == null || parsed < 0) {
                          return 'Use a non-negative integer';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00D1C1)),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_title),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _languageDropdown() {
    final disabled = _languages.isEmpty;
    return DropdownButtonFormField<LearningLanguage>(
      value: _selectedLanguage,
      decoration: const InputDecoration(labelText: 'Language'),
      items: _languages
          .map((language) => DropdownMenuItem<LearningLanguage>(
                value: language,
                child: Text('${language.name} (${language.code.toUpperCase()})'),
              ))
          .toList(),
      onChanged: disabled
          ? null
          : (value) async {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedLanguage = value;
                _selectedLevel = null;
                _selectedLesson = null;
                _levels = const [];
                _lessons = const [];
              });
              if (widget.type != AdminAddContentType.level) {
                await _loadLevels(value.code);
              }
            },
    );
  }

  Widget _levelDropdown() {
    return DropdownButtonFormField<LearningLevel>(
      value: _selectedLevel,
      decoration: const InputDecoration(labelText: 'Level'),
      items: _levels
          .map(
            (level) => DropdownMenuItem<LearningLevel>(
              value: level,
              child: Text('${level.name.toUpperCase()} (order ${level.orderIndex})'),
            ),
          )
          .toList(),
      validator: (_) {
        if (_selectedLevel == null) {
          return 'Please select a level';
        }
        return null;
      },
      onChanged: _levels.isEmpty
          ? null
          : (value) async {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedLevel = value;
                _selectedLesson = null;
                _lessons = const [];
              });
              if (widget.type == AdminAddContentType.word) {
                await _loadLessons(value.id);
              }
            },
    );
  }

  Widget _lessonDropdown() {
    return DropdownButtonFormField<LearningLesson>(
      value: _selectedLesson,
      decoration: const InputDecoration(labelText: 'Lesson'),
      items: _lessons
          .map(
            (lesson) => DropdownMenuItem<LearningLesson>(
              value: lesson,
              child: Text('${lesson.name} (#${lesson.id})'),
            ),
          )
          .toList(),
      validator: (_) {
        if (_selectedLesson == null) {
          return 'Please select a lesson';
        }
        return null;
      },
      onChanged: _lessons.isEmpty
          ? null
          : (value) {
              setState(() => _selectedLesson = value);
            },
    );
  }
}
