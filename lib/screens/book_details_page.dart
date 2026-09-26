import 'package:flutter/material.dart';

import '../models/book_record.dart';
import '../models/lesson_record.dart';
import '../services/lesson_storage_service.dart';
import 'pdf_page_selector.dart';
import 'teaching_board_page.dart';

class BookDetailsPage extends StatefulWidget {
  const BookDetailsPage({super.key, required this.book});

  final BookRecord book;

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  final LessonStorageService _storage = LessonStorageService.instance;

  List<LessonRecord> _lessons = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final lessons = await _storage.loadLessonsForBook(widget.book.id);

      if (!mounted) return;

      setState(() {
        _lessons = lessons;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Load lessons error: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _createLesson() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfPageSelector(
          bookId: widget.book.id,
          pdfPath: widget.book.filePath,
          bookName: widget.book.name,
        ),
      ),
    );

    if (!mounted) return;

    await _loadLessons();
  }

  Future<void> _openLesson(LessonRecord lesson) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeachingBoardPage(
          pdfPath: widget.book.filePath,
          bookName: widget.book.name,
          pages: lesson.pages,
          lessonId: lesson.id,
          lessonName: lesson.name,
        ),
      ),
    );

    if (!mounted) return;

    await _loadLessons();
  }

  String _pagesText(LessonRecord lesson) {
    if (lesson.pages.isEmpty) {
      return 'بدون صفحات';
    }

    if (lesson.pages.length <= 6) {
      return lesson.pages.join('، ');
    }

    final firstPages = lesson.pages.take(6).join('، ');

    return '$firstPages ...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      appBar: AppBar(
        title: Text(widget.book.name, overflow: TextOverflow.ellipsis),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createLesson,
        icon: const Icon(Icons.add),
        label: const Text('حصة جديدة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lessons.isEmpty
          ? _buildEmptyState()
          : _buildLessons(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school_outlined,
            size: 90,
            color: Colors.blueGrey.shade400,
          ),
          const SizedBox(height: 18),
          const Text(
            'الحصص المحفوظة',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم إنشاء حصص لهذا الكتاب بعد',
            style: TextStyle(fontSize: 17, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _createLesson,
            icon: const Icon(Icons.add),
            label: const Text('إنشاء أول حصة'),
          ),
        ],
      ),
    );
  }

  Widget _buildLessons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
          child: Text(
            'الحصص المحفوظة',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            '${_lessons.length} حصة',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 90),
            itemCount: _lessons.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lesson = _lessons[index];

              return Card(
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    radius: 27,
                    child: Text('${lesson.pages.length}'),
                  ),
                  title: Text(
                    lesson.name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'الصفحات: '
                      '${_pagesText(lesson)}',
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_back_ios_new),
                  onTap: () {
                    _openLesson(lesson);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
