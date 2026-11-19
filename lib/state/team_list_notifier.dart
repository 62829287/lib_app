import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import '../models/team.dart';
import '../repositories/team_repository.dart';
import 'load_status.dart';

class TeamListNotifier extends ChangeNotifier {
  TeamListNotifier(this._repository);

  final TeamRepository _repository;

  ListQuery _query = const ListQuery(sortField: 'name');
  PageResult<Team> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<String> _selected = {};

  ListQuery get query => _query;
  PageResult<Team> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<String> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  List<Team> get selectedItems =>
      _result.items.where((t) => _selected.contains(t.id)).toList();

  bool get selectionHasActive => selectedItems.any((t) => !t.isDeleted);
  bool get selectionHasDeleted => selectedItems.any((t) => t.isDeleted);

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

  void toggleSelection(String id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  Future<void> softDeleteSelected() async {
    await _repository.softDeleteMany(
      selectedItems.where((t) => !t.isDeleted).map((t) => t.id).toList(),
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
      selectedItems.where((t) => t.isDeleted).map((t) => t.id).toList(),
    );
    _selected.clear();
    await load();
  }

  Future<void> softDelete(String id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<void> hardDelete(String id) async {
    await _repository.hardDelete(id);
    await load();
  }

  Future<void> restore(String id) async {
    await _repository.restore(id);
    await load();
  }
}
