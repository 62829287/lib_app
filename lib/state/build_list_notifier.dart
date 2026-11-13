import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/build.dart';
import '../models/build_query.dart';
import '../models/page_result.dart';
import '../repositories/build_repository.dart';
import 'load_status.dart';

class BuildListNotifier extends ChangeNotifier {
  BuildListNotifier(this._repository);

  final BuildRepository _repository;

  BuildQuery _query = const BuildQuery();
  PageResult<Build> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  BuildQuery get query => _query;
  PageResult<Build> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  List<Build> get selectedItems =>
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
    } on RequestCancelledException {
      return;
    } on ApiException catch (e) {
      _error = e.message;
      _status = LoadStatus.error;
    } catch (e) {
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(BuildQuery next) async {
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
