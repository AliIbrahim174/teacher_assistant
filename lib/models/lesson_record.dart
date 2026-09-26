class LessonRecord {
  const LessonRecord({
    required this.id,
    required this.bookId,
    required this.name,
    required this.pages,
    required this.createdAt,
    required this.updatedAt,
    this.annotations = const {},
  });

  final String id;
  final String bookId;
  final String name;
  final List<int> pages;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Prepared now for v0.5B2.
  /// Key = PDF page number.
  final Map<int, List<Map<String, dynamic>>> annotations;

  LessonRecord copyWith({
    String? name,
    List<int>? pages,
    DateTime? updatedAt,
    Map<int, List<Map<String, dynamic>>>? annotations,
  }) {
    return LessonRecord(
      id: id,
      bookId: bookId,
      name: name ?? this.name,
      pages: pages ?? this.pages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      annotations: annotations ?? this.annotations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'name': name,
      'pages': pages,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'annotations': annotations.map(
        (page, items) => MapEntry(page.toString(), items),
      ),
    };
  }

  factory LessonRecord.fromJson(Map<String, dynamic> json) {
    final rawAnnotations = json['annotations'];

    final annotations = <int, List<Map<String, dynamic>>>{};

    if (rawAnnotations is Map) {
      for (final entry in rawAnnotations.entries) {
        final page = int.tryParse(entry.key.toString());

        final value = entry.value;

        if (page == null || value is! List) {
          continue;
        }

        annotations[page] = value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return LessonRecord(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      name: json['name'] as String,
      pages: (json['pages'] as List).map((page) => page as int).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      annotations: annotations,
    );
  }
}
