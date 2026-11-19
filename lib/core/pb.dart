import '../models/page_result.dart';

String pbRecords(String collection) => '/api/collections/$collection/records';

String pbRecord(String collection, String id) =>
    '/api/collections/$collection/records/$id';

DateTime? pbDate(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

String pbId(dynamic value) => value == null ? '' : '$value';

List<String> pbIdList(dynamic value) {
  if (value is! List) return const [];
  return value.map((e) => '$e').where((e) => e.isNotEmpty).toList();
}

PageResult<T> pbPageResult<T>(
  Map<String, dynamic> data,
  T Function(Map<String, dynamic>) mapItem, {
  required int fallbackPage,
  required int fallbackSize,
}) {
  final items = (data['items'] as List? ?? const [])
      .whereType<Map>()
      .map((e) => mapItem(Map<String, dynamic>.from(e)))
      .toList();
  return PageResult(
    items: items,
    page: (data['page'] as num?)?.toInt() ?? fallbackPage,
    size: (data['perPage'] as num?)?.toInt() ?? fallbackSize,
    total: (data['totalItems'] as num?)?.toInt() ?? items.length,
  );
}

String pbSort(String field, bool ascending) =>
    ascending ? field : '-$field';

String? pbDeletedFilter({required bool includeDeleted, String? searchField, String? search}) {
  final parts = <String>[];
  if (!includeDeleted) {
    parts.add('(deletedAt = "" || deletedAt = null)');
  }
  final q = search?.trim() ?? '';
  if (searchField != null && q.isNotEmpty) {
    final safe = q.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
    parts.add('$searchField ~ "$safe"');
  }
  if (parts.isEmpty) return null;
  return parts.join(' && ');
}
