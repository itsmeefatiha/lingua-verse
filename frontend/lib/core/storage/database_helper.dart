import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Singleton DatabaseHelper for offline-first SQLite storage
/// Manages local caching of languages, levels, lessons, and words
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initializeDatabase();
    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'linguaverse.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Languages table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS languages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT UNIQUE NOT NULL,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Levels table (CEFR levels like A1, A2, etc.)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS levels (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        language_id INTEGER NOT NULL,
        display_order INTEGER DEFAULT 0,
        is_completed INTEGER DEFAULT 0,
        is_locked INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE CASCADE,
        UNIQUE(code, language_id)
      )
    ''');

    // Lessons table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lessons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        level_id INTEGER NOT NULL,
        display_order INTEGER DEFAULT 0,
        is_completed INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (level_id) REFERENCES levels(id) ON DELETE CASCADE
      )
    ''');

    // Words/Vocabulary table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lesson_id INTEGER NOT NULL,
        native_text TEXT NOT NULL,
        target_text TEXT NOT NULL,
        image_url TEXT,
        audio_url TEXT,
        category TEXT,
        example TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE
      )
    ''');

    // Create indices for faster queries
    await db.execute('CREATE INDEX IF NOT EXISTS idx_levels_language ON levels(language_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_lessons_level ON lessons(level_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_words_lesson ON words(lesson_id)');
  }

  // ============================================================
  // UPSERT METHODS (Insert or Update using ConflictAlgorithm)
  // ============================================================

  /// Upsert a single language
  Future<int> upsertLanguage({
    required int id,
    required String name,
    required String code,
  }) async {
    final db = await database;
    return await db.insert(
      'languages',
      {
        'id': id,
        'name': name,
        'code': code,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Upsert multiple languages in a transaction
  Future<void> upsertLanguages(List<Map<String, dynamic>> languages) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final language in languages) {
        await txn.insert(
          'languages',
          {
            'id': language['id'] ?? language['language_id'],
            'name': language['name'] ?? '',
            'code': language['code'] ?? '',
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Upsert a single level
  Future<int> upsertLevel({
    required int id,
    required String name,
    required String code,
    required int languageId,
    required int displayOrder,
    bool isCompleted = false,
    bool isLocked = true,
  }) async {
    final db = await database;
    return await db.insert(
      'levels',
      {
        'id': id,
        'name': name,
        'code': code,
        'language_id': languageId,
        'display_order': displayOrder,
        'is_completed': isCompleted ? 1 : 0,
        'is_locked': isLocked ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Upsert multiple levels in a transaction
  Future<void> upsertLevels(List<Map<String, dynamic>> levels) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final level in levels) {
        await txn.insert(
          'levels',
          {
            'id': level['id'],
            'name': level['name'] ?? level['code'] ?? '',
            'code': level['code'] ?? '',
            'language_id': level['language_id'] ?? 0,
            'display_order': level['display_order'] ?? level['order_index'] ?? 0,
            'is_completed': (level['is_completed'] == true) ? 1 : 0,
            'is_locked': (level['is_locked'] == true) ? 1 : 0,
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Upsert a single lesson
  Future<int> upsertLesson({
    required int id,
    required String title,
    required int levelId,
    required int displayOrder,
    String? description,
    bool isCompleted = false,
  }) async {
    final db = await database;
    return await db.insert(
      'lessons',
      {
        'id': id,
        'title': title,
        'description': description ?? '',
        'level_id': levelId,
        'display_order': displayOrder,
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Upsert multiple lessons in a transaction
  Future<void> upsertLessons(List<Map<String, dynamic>> lessons) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final lesson in lessons) {
        await txn.insert(
          'lessons',
          {
            'id': lesson['id'],
            'title': lesson['title'] ?? lesson['name'] ?? '',
            'description': lesson['description'] ?? '',
            'level_id': lesson['level_id'] ?? 0,
            'display_order': lesson['display_order'] ?? lesson['order_index'] ?? 0,
            'is_completed': (lesson['is_completed'] == true) ? 1 : 0,
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Upsert a single word/vocabulary
  Future<int> upsertWord({
    required int id,
    required int lessonId,
    required String nativeText,
    required String targetText,
    String? imageUrl,
    String? audioUrl,
    String? category,
    String? example,
  }) async {
    final db = await database;
    return await db.insert(
      'words',
      {
        'id': id,
        'lesson_id': lessonId,
        'native_text': nativeText,
        'target_text': targetText,
        'image_url': imageUrl ?? '',
        'audio_url': audioUrl ?? '',
        'category': category ?? 'general',
        'example': example ?? '',
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Upsert multiple words in a transaction
  Future<void> upsertWords(List<Map<String, dynamic>> words) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final word in words) {
        await txn.insert(
          'words',
          {
            'id': word['id'],
            'lesson_id': word['lesson_id'] ?? 0,
            'native_text': word['translation'] ?? word['native_text'] ?? '',
            'target_text': word['term'] ?? word['target_text'] ?? '',
            'image_url': word['image_url'] ?? '',
            'audio_url': word['audio_url'] ?? '',
            'category': word['category'] ?? 'general',
            'example': word['example'] ?? '',
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ============================================================
  // READ METHODS
  // ============================================================

  /// Get all cached languages
  Future<List<Map<String, dynamic>>> getCachedLanguages() async {
    final db = await database;
    return await db.query(
      'languages',
      orderBy: 'name ASC',
    );
  }

  /// Get all cached levels for a specific language
  Future<List<Map<String, dynamic>>> getCachedLevels(int languageId) async {
    final db = await database;
    return await db.query(
      'levels',
      where: 'language_id = ?',
      whereArgs: [languageId],
      orderBy: 'display_order ASC, id ASC',
    );
  }

  /// Get a specific level by ID
  Future<Map<String, dynamic>?> getCachedLevel(int levelId) async {
    final db = await database;
    final results = await db.query(
      'levels',
      where: 'id = ?',
      whereArgs: [levelId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Get all cached lessons for a specific level
  Future<List<Map<String, dynamic>>> getCachedLessons(int levelId) async {
    final db = await database;
    return await db.query(
      'lessons',
      where: 'level_id = ?',
      whereArgs: [levelId],
      orderBy: 'display_order ASC, id ASC',
    );
  }

  /// Get a specific lesson by ID
  Future<Map<String, dynamic>?> getCachedLesson(int lessonId) async {
    final db = await database;
    final results = await db.query(
      'lessons',
      where: 'id = ?',
      whereArgs: [lessonId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Get all cached words for a specific lesson
  Future<List<Map<String, dynamic>>> getCachedWords(int lessonId) async {
    final db = await database;
    return await db.query(
      'words',
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
      orderBy: 'id ASC',
    );
  }

  /// Get a specific word by ID
  Future<Map<String, dynamic>?> getCachedWord(int wordId) async {
    final db = await database;
    final results = await db.query(
      'words',
      where: 'id = ?',
      whereArgs: [wordId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Update a level's completion status
  Future<int> updateLevelCompletion(int levelId, bool isCompleted) async {
    final db = await database;
    return await db.update(
      'levels',
      {
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [levelId],
    );
  }

  /// Update a lesson's completion status
  Future<int> updateLessonCompletion(int lessonId, bool isCompleted) async {
    final db = await database;
    return await db.update(
      'lessons',
      {
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [lessonId],
    );
  }

  /// Update a level's lock status
  Future<int> updateLevelLockStatus(int levelId, bool isLocked) async {
    final db = await database;
    return await db.update(
      'levels',
      {
        'is_locked': isLocked ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [levelId],
    );
  }

  /// Clear all cached data (useful for user logout or refresh)
  Future<void> clearAllCache() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('words');
      await txn.delete('lessons');
      await txn.delete('levels');
      await txn.delete('languages');
    });
  }

  /// Clear cache for a specific language
  Future<void> clearLanguageCache(int languageId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Get all level IDs for this language
      final levels = await txn.query(
        'levels',
        columns: ['id'],
        where: 'language_id = ?',
        whereArgs: [languageId],
      );

      // Delete all words from lessons in these levels
      for (final level in levels) {
        await txn.delete(
          'words',
          where: 'lesson_id IN (SELECT id FROM lessons WHERE level_id = ?)',
          whereArgs: [level['id']],
        );
      }

      // Delete all lessons in these levels
      await txn.delete(
        'lessons',
        where: 'level_id IN (SELECT id FROM levels WHERE language_id = ?)',
        whereArgs: [languageId],
      );

      // Delete the levels
      await txn.delete(
        'levels',
        where: 'language_id = ?',
        whereArgs: [languageId],
      );
    });
  }

  /// Close the database connection (rarely needed)
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
