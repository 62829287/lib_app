import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import '../repositories/book_repository.dart';
import 'load_status.dart';

class BookListNotifier extends ChangeNotifier {
  BookListNotifier(this._repository);

  final BookRepository _repository;

  BookQuery _query = const BookQuery();
  PageResult<Book> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  BookQuery get query => _query;
  PageResult<Book> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  bool get isEmptySuccess =>
      _status == LoadStatus.success && _result.items.isEmpty;

  List<Book> get selectedItems =>
      _result.items.where((b) => _selected.contains(b.id)).toList();

  bool get selectionHasActive => selectedItems.any((b) => !b.isDeleted);
  bool get selectionHasDeleted => selectedItems.any((b) => b.isDeleted);

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(BookQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  Future<void> softDeleteSelected() async {
    final ids =
        selectedItems.where((b) => !b.isDeleted).map((b) => b.id).toList();
    if (ids.isEmpty) return;
    await _repository.softDeleteMany(ids);
    _selected.clear();
    await load();
  }

  Future<void> hardDeleteSelected() async {
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    await _repository.hardDeleteMany(ids);
    _selected.clear();
    await load();
  }

  Future<void> restoreSelected() async {
    final ids =
        selectedItems.where((b) => b.isDeleted).map((b) => b.id).toList();
    if (ids.isEmpty) return;
    await _repository.restoreMany(ids);
    _selected.clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }
}
