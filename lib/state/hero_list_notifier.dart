import 'package:flutter/foundation.dart';

import '../models/dota_hero.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import '../repositories/hero_repository.dart';
import 'load_status.dart';

class HeroListNotifier extends ChangeNotifier {
  HeroListNotifier(this._repository);

  final HeroRepository _repository;

  ListQuery _query = const ListQuery(sortField: 'name');
  PageResult<DotaHero> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  ListQuery get query => _query;
  PageResult<DotaHero> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  List<DotaHero> get selectedItems =>
      _result.items.where((h) => _selected.contains(h.id)).toList();

  bool get selectionHasActive => selectedItems.any((h) => !h.isDeleted);
  bool get selectionHasDeleted => selectedItems.any((h) => h.isDeleted);

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = '$e';
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
      selectedItems.where((h) => !h.isDeleted).map((h) => h.id).toList(),
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
      selectedItems.where((h) => h.isDeleted).map((h) => h.id).toList(),
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
