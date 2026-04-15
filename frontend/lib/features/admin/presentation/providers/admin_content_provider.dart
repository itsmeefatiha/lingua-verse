import 'package:flutter/foundation.dart';

import '../../../learning/data/models/learning_engine_models.dart';
import '../../data/repositories/admin_repository.dart';

class AdminContentProvider extends ChangeNotifier {
  AdminContentProvider(this._repository);

  final AdminRepository _repository;

  List<LearningLanguage> _languages = const [];
  List<LearningLevel> _levels = const [];
  List<LearningLesson> _lessons = const [];
  List<LearningWord> _words = const [];
  String? _selectedLanguageCode;
  int? _selectedLevelId;
  bool _isLoading = false;
  String? _error;

  List<LearningLanguage> get languages => _languages;
  List<LearningLevel> get levels => _levels;
  List<LearningLesson> get lessons => _lessons;
  List<LearningWord> get words => _words;
  String? get selectedLanguageCode => _selectedLanguageCode;
  int? get selectedLevelId => _selectedLevelId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLanguages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _languages = await _repository.fetchLanguages();
      if (_languages.isNotEmpty) {
        _selectedLanguageCode ??= _languages.first.code;
        await loadLevels(_selectedLanguageCode!);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLevels(String languageCode) async {
    _selectedLanguageCode = languageCode;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final language = _languages.firstWhere(
        (item) => item.code == languageCode,
        orElse: () => LearningLanguage(id: 0, name: languageCode.toUpperCase(), code: languageCode),
      );
      _levels = await _repository.fetchLevelsForLanguage(languageCode, languageId: language.id);
      if (_levels.isNotEmpty) {
        _selectedLevelId ??= _levels.first.id;
        await loadLessons(_selectedLevelId!);
      } else {
        _lessons = const [];
        _words = const [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLessons(int levelId) async {
    _selectedLevelId = levelId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final level = _levels.firstWhere((item) => item.id == levelId);
      _lessons = await _repository.fetchLessonsForLevel(
        levelId: levelId,
        levelName: level.name,
        languageCode: _selectedLanguageCode,
      );
      if (_lessons.isNotEmpty) {
        await loadWords(_lessons.first.id);
      } else {
        _words = const [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWords(int lessonId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _words = await _repository.fetchWordsForLesson(lessonId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
