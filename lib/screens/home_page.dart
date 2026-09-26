import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/book_record.dart';
import '../services/book_storage_service.dart';
import 'pdf_page_selector.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.loadBooksOverride});

  final Future<List<BookRecord>> Function()? loadBooksOverride;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BookStorageService _storage = BookStorageService.instance;

  List<BookRecord> _books = [];

  bool _loadingBooks = true;

  bool _addingBook = false;

  @override
  void initState() {
    super.initState();

    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final books = widget.loadBooksOverride != null
          ? await widget.loadBooksOverride!()
          : await _storage.loadBooks();
      if (!mounted) return;

      setState(() {
        _books = books;
        _loadingBooks = false;
      });
    } catch (e) {
      debugPrint('Load books error: $e');

      if (!mounted) return;

      setState(() {
        _loadingBooks = false;
      });
    }
  }

  Future<void> _addBook() async {
    if (_addingBook) {
      return;
    }

    setState(() {
      _addingBook = true;
    });

    try {
      final selectedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (!mounted) return;

      if (selectedFile == null) {
        return;
      }

      final sourcePath = selectedFile.path;

      if (sourcePath == null) {
        _showMessage('تعذر فتح الملف، برجاء اختيار ملف PDF محفوظ على الجهاز.');

        return;
      }

      final book = await _storage.importBook(
        sourcePath: sourcePath,
        originalFileName: selectedFile.name,
      );

      if (!mounted) return;

      await _loadBooks();

      if (!mounted) return;

      _showMessage('تم حفظ الكتاب بنجاح.');

      await _openBook(book);
    } catch (e) {
      debugPrint('Import book error: $e');

      if (!mounted) return;

      _showMessage('حدث خطأ أثناء حفظ الكتاب.');
    } finally {
      if (mounted) {
        setState(() {
          _addingBook = false;
        });
      }
    }
  }

  Future<void> _openBook(BookRecord book) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PdfPageSelector(pdfPath: book.filePath, bookName: book.name),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textDirection: TextDirection.rtl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      appBar: AppBar(title: const Text('مساعد المعلمة'), centerTitle: true),
      floatingActionButton: _loadingBooks
          ? null
          : FloatingActionButton.extended(
              onPressed: _addingBook ? null : _addBook,
              icon: _addingBook
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_addingBook ? 'جارٍ الحفظ...' : 'إضافة كتاب'),
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingBooks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_books.isEmpty) {
      return _buildEmptyLibrary();
    }

    return _buildLibrary();
  }

  Widget _buildEmptyLibrary() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 95,
            color: Colors.blueGrey.shade400,
          ),

          const SizedBox(height: 18),

          const Text(
            'مكتبتي',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'لا توجد كتب مضافة حتى الآن',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
          ),

          const SizedBox(height: 26),

          FilledButton.icon(
            onPressed: _addingBook ? null : _addBook,
            icon: const Icon(Icons.add),
            label: const Text('إضافة أول كتاب'),
          ),
        ],
      ),
    );
  }

  Widget _buildLibrary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200 ? 4 : 3;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 18, 24, 6),
              child: Text(
                'مكتبتي',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '${_books.length} كتاب',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 90),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 1.65,
                ),
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  final book = _books[index];

                  return _BookCard(
                    book: book,
                    onTap: () {
                      _openBook(book);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.onTap});

  final BookRecord book;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 88,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 42,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      book.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${book.pageCount} صفحة',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Row(
                      children: [
                        Icon(Icons.touch_app_outlined, size: 18),
                        SizedBox(width: 5),
                        Text('اضغطي لفتح الكتاب'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
