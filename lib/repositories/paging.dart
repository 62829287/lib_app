import '../models/page_result.dart';

PageResult<T> paginate<T>(
  List<T> rows, {
  required int page,
  required int size,
}) {
  final total = rows.length;
  final from = (page - 1) * size;
  final to = (from + size) > total ? total : (from + size);
  final items = from >= total ? <T>[] : rows.sublist(from, to);
  return PageResult(items: items, page: page, size: size, total: total);
}
