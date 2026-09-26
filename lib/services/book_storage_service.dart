import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../models/book_record.dart';

class BookStorageService {
  BookStorageService._();

  static final BookStorageService instance =
      BookStorageService._();

  Future<Directory>
      _getAppRootDirectory() async {
    final documentsDirectory =
        await getApplicationDocumentsDirectory();

    final rootDirectory = Directory(
      p.join(
        documentsDirectory.path,
        'teacher_assistant',
      ),
    );

    if (!await rootDirectory.exists()) {
      await rootDirectory.create(
        recursive: true,
      );
    }

    return rootDirectory;
  }

  Future<Directory>
      _getBooksDirectory() async {
    final root =
        await _getAppRootDirectory();

    final booksDirectory = Directory(
      p.join(
        root.path,
        'books',
      ),
    );

    if (!await booksDirectory.exists()) {
      await booksDirectory.create(
        recursive: true,
      );
    }

    return booksDirectory;
  }

  Future<Directory>
      _getDataDirectory() async {
    final root =
        await _getAppRootDirectory();

    final dataDirectory = Directory(
      p.join(
        root.path,
        'data',
      ),
    );

    if (!await dataDirectory.exists()) {
      await dataDirectory.create(
        recursive: true,
      );
    }

    return dataDirectory;
  }

  Future<File> _getBooksDataFile() async {
    final dataDirectory =
        await _getDataDirectory();

    return File(
      p.join(
        dataDirectory.path,
        'books.json',
      ),
    );
  }

  Future<List<BookRecord>>
      loadBooks() async {
    final file =
        await _getBooksDataFile();

    if (!await file.exists()) {
      return [];
    }

    final content =
        await file.readAsString();

    if (content.trim().isEmpty) {
      return [];
    }

    final decoded =
        jsonDecode(content);

    if (decoded is! List) {
      return [];
    }

    final books = decoded
        .map(
          (item) =>
              BookRecord.fromJson(
            Map<String, dynamic>.from(
              item as Map,
            ),
          ),
        )
        .toList();

    final existingBooks =
        <BookRecord>[];

    for (final book in books) {
      final pdfFile =
          File(book.filePath);

      if (await pdfFile.exists()) {
        existingBooks.add(book);
      }
    }

    existingBooks.sort(
      (a, b) => b.addedAt.compareTo(
        a.addedAt,
      ),
    );

    return existingBooks;
  }

  Future<BookRecord> importBook({
    required String sourcePath,
    required String originalFileName,
  }) async {
    final sourceFile =
        File(sourcePath);

    if (!await sourceFile.exists()) {
      throw Exception(
        'Source PDF does not exist.',
      );
    }

    final booksDirectory =
        await _getBooksDirectory();

    final id = DateTime.now()
        .microsecondsSinceEpoch
        .toString();

    final destinationPath = p.join(
      booksDirectory.path,
      'book_$id.pdf',
    );

    final destinationFile =
        await sourceFile.copy(
      destinationPath,
    );

    PdfDocument? document;

    try {
      document =
          await PdfDocument.openFile(
        destinationFile.path,
      );

      final pageCount =
          document.pagesCount;

      final cleanName =
          _cleanBookName(
        originalFileName,
      );

      final book = BookRecord(
        id: id,
        name: cleanName,
        filePath:
            destinationFile.path,
        pageCount: pageCount,
        addedAt: DateTime.now(),
      );

      final books =
          await loadBooks();

      books.insert(
        0,
        book,
      );

      await _saveBooks(books);

      return book;
    } catch (_) {
      if (await destinationFile.exists()) {
        await destinationFile.delete();
      }

      rethrow;
    } finally {
      if (document != null &&
          !document.isClosed) {
        await document.close();
      }
    }
  }

  Future<void> _saveBooks(
    List<BookRecord> books,
  ) async {
    final file =
        await _getBooksDataFile();

    final json = jsonEncode(
      books
          .map(
            (book) =>
                book.toJson(),
          )
          .toList(),
    );

    await file.writeAsString(
      json,
      flush: true,
    );
  }

  String _cleanBookName(
    String fileName,
  ) {
    final extension =
        p.extension(fileName);

    if (extension.isEmpty) {
      return fileName;
    }

    return p.basenameWithoutExtension(
      fileName,
    );
  }
}