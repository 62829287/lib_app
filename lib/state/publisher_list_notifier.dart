import "package:flutter/foundation.dart";

import "../models/list_query.dart";
import "../models/page_result.dart";
import "../models/publisher.dart";
import "../repositories/publisher_repository.dart";
import "load_status.dart";

class PublisherListNotifier extends ChangeNotifier {
  PublisherListNotifier(this._repository);
  final PublisherRepository _repository;

  ListQuery _query = const ListQuery(sortField: "name");
  PageResult<Publisher> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  ListQuery get query => _query;
  PageResult<Publisher> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  List<Publisher> get selectedItems =>
      _result.items.where((p) => _selected.contains(p.id)).toList();
  bool get selectionHasActive => selectedItems.any((p) => !p.isDeleted);
  bool get selectionHasDeleted => selectedItems.any((p) => p.isDeleted);

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = "$e";
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(ListQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  Future<void> softDeleteSelected() async {
    await _repository.softDeleteMany(
      selectedItems.where((p) => !p.isDeleted).map((p) => p.id).toList(),
    );
    _selected.clear();
    await load();
  }

  Future<void> hardDeleteSelected() async {
    await _repository.hardDeleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> restoreSelected() async {
    await _repository.restoreMany(
      selectedItems.where((p) => p.isDeleted).map((p) => p.id).toList(),
    );
    _selected.clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }
}