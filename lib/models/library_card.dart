class LibraryCard {
  final String number;
  final DateTime issuedAt;
  final DateTime expiresAt;

  const LibraryCard({
    required this.number,
    required this.issuedAt,
    required this.expiresAt,
  });

  LibraryCard copyWith({
    String? number,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) {
    return LibraryCard(
      number: number ?? this.number,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory LibraryCard.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      final now = DateTime.now();
      return LibraryCard(
        number: '',
        issuedAt: now,
        expiresAt: now.add(const Duration(days: 365)),
      );
    }
    return LibraryCard(
      number: json['number'] as String? ?? '',
      issuedAt: DateTime.tryParse('${json['issuedAt']}') ?? DateTime.now(),
      expiresAt: DateTime.tryParse('${json['expiresAt']}') ??
          DateTime.now().add(const Duration(days: 365)),
    );
  }
}