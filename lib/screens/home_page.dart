import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'pdf_page_selector.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _openingBook = false;

  Future<void> _addBook() async {
    if (_openingBook) return;

    setState(() {
      _openingBook = true;
    });

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (!mounted) return;

      if (file == null) {
        return;
      }

      final path = file.path;

      if (path == null) {
        _showMessage('تعذر فتح الملف، برجاء اختيار ملف PDF محفوظ على الجهاز.');
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfPageSelector(
            pdfPath: path,
            bookName: _cleanFileName(file.name),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage('حدث خطأ أثناء فتح الكتاب.');

      debugPrint('PDF picker error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _openingBook = false;
        });
      }
    }
  }

  String _cleanFileName(String name) {
    if (name.toLowerCase().endsWith('.pdf')) {
      return name.substring(0, name.length - 4);
    }

    return name;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textDirection: TextDirection.rtl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f8fa),
      appBar: AppBar(title: const Text('مساعد المعلمة'), centerTitle: true),
      body: Center(
        child: _openingBook
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جارٍ فتح الكتاب...', style: TextStyle(fontSize: 18)),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book_rounded, size: 90),
                  const SizedBox(height: 20),
                  const Text(
                    'الكتب',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أضيفي الكتاب ثم اختاري صفحات الحصة',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _addBook,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 18,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة كتاب'),
                  ),
                ],
              ),
      ),
    );
  }
}
