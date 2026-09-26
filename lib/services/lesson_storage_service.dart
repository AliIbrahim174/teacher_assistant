import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/lesson_record.dart';

class LessonStorageService {
  LessonStorageService._();

  static final LessonStorageService instance = LessonStorageService._();

  Future<Directory> _getLessonsDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();

    final directory = Directory(
      p.join(documentsDirectory.path, 'teacher_assistant', 'data', 'lessons'),
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<File> _lessonFile(String lessonId) async {
    final directory = await _getLessonsDirectory();

    return File(p.join(directory.path, 'lesson_$lessonId.json'));
  }

  Future<LessonRecord> createLesson({
    required String bookId,
    required String name,
    required List<int> pages,
  }) async {
    final now = DateTime.now();

    final lesson = LessonRecord(
      id: now.microsecondsSinceEpoch.toString(),
      bookId: bookId,
      name: name,
      pages: List<int>.from(pages)..sort(),
      createdAt: now,
      updatedAt: now,
    );

    await saveLesson(lesson);

    return lesson;
  }

  Future<void> saveLesson(LessonRecord lesson) async {
    final file = await _lessonFile(lesson.id);

    await file.writeAsString(jsonEncode(lesson.toJson()), flush: true);
  }

  Future<LessonRecord?> loadLesson(String lessonId) async {
    final file = await _lessonFile(lessonId);

    if (!await file.exists()) {
      return null;
    }

    final content = await file.readAsString();

    if (content.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(content);

    if (decoded is! Map) {
      return null;
    }

    return LessonRecord.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<List<LessonRecord>> loadLessonsForBook(String bookId) async {
    final directory = await _getLessonsDirectory();

    final lessons = <LessonRecord>[];

    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.json')) {
        continue;
      }

      try {
        final content = await entity.readAsString();

        if (content.trim().isEmpty) {
          continue;
        }

        final decoded = jsonDecode(content);

        if (decoded is! Map) {
          continue;
        }

        final lesson = LessonRecord.fromJson(
          Map<String, dynamic>.from(decoded),
        );

        if (lesson.bookId == bookId) {
          lessons.add(lesson);
        }
      } catch (e) {
        // One damaged lesson must not break
        // the entire teacher library.
        continue;
      }
    }

    lessons.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return lessons;
  }

  Future<LessonRecord?> saveAnnotations({
    required String lessonId,
    required Map<int, List<Map<String, dynamic>>> annotations,
  }) async {
    final lesson = await loadLesson(lessonId);

    if (lesson == null) {
      return null;
    }

    final safeAnnotations = <int, List<Map<String, dynamic>>>{};

    for (final entry in annotations.entries) {
      safeAnnotations[entry.key] = entry.value
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    final updatedLesson = lesson.copyWith(
      updatedAt: DateTime.now(),
      annotations: safeAnnotations,
    );

    await saveLesson(updatedLesson);

    return updatedLesson;
  }
}
