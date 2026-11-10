class Book {
  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;
  final int publisherId;
  final List<int> authorIds;
  final List<int> genreIds;
  final int copiesTotal;
  final int copiesAvailable;
  final DateTime? deletedAt;

  const Book({
    required this.id,
    required this.title,
    required this.isbn,
    required this.year,
    required this.pages,
    required this.publisherId,
    required this.authorIds,
    required this.genreIds,
    required this.copiesTotal,
    required this.copiesAvailable,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Book copyWith({
    int? id,
    String? title,
    String? isbn,
    int? year,
    int? pages,
    int? publisherId,
    List<int>? authorIds,
    List<int>? genreIds,
    int? copiesTotal,
    int? copiesAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      isbn: isbn ?? this.isbn,
      year: year ?? this.year,
      pages: pages ?? this.pages,
      publisherId: publisherId ?? this.publisherId,
      authorIds: authorIds ?? List<int>.from(this.authorIds),
      genreIds: genreIds ?? List<int>.from(this.genreIds),
      copiesTotal: copiesTotal ?? this.copiesTotal,
      copiesAvailable: copiesAvailable ?? this.copiesAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isbn': isbn,
        'year': year,
        'pages': pages,
        'publisherId': publisherId,
        'authorIds': authorIds,
        'genreIds': genreIds,
        'copiesTotal': copiesTotal,
        'copiesAvailable': copiesAvailable,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        isbn: json['isbn'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? 0,
        pages: (json['pages'] as num?)?.toInt() ?? 0,
        publisherId: (json['publisherId'] as num?)?.toInt() ?? 0,
        authorIds: _toIntList(json['authorIds']),
        genreIds: _toIntList(json['genreIds']),
        copiesTotal: (json['copiesTotal'] as num?)?.toInt() ?? 0,
        copiesAvailable: (json['copiesAvailable'] as num?)?.toInt() ?? 0,
        deletedAt: _parseDate(json['deletedAt']),
      );
}

List<int> _toIntList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((e) => e is num ? e.toInt() : int.tryParse('$e'))
      .whereType<int>()
      .toList();
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
