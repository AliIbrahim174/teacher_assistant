class BookRecord {
  const BookRecord({
    required this.id,
    required this.name,
    required this.filePath,
    required this.pageCount,
    required this.addedAt,
  });

  final String id;
  final String name;
  final String filePath;
  final int pageCount;
  final DateTime addedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'pageCount': pageCount,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory BookRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    return BookRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      filePath: json['filePath'] as String,
      pageCount: json['pageCount'] as int,
      addedAt: DateTime.parse(
        json['addedAt'] as String,
      ),
    );
  }
}