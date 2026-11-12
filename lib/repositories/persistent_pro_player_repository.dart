import '../models/page_result.dart';
import '../models/pro_player.dart';
import '../models/pro_player_query.dart';
import 'json_store.dart';
import 'paging.dart';
import 'pro_player_repository.dart';
import 'seed_data.dart';

class PersistentProPlayerRepository implements ProPlayerRepository {
  PersistentProPlayerRepository(this._store);

  static const _key = 'dota_pros_v2';
  final JsonStore _store;
  late List<ProPlayer> _items;
  late int _nextId;

  void loadFromStorage() {
    final raw = _store.readList(_key);
    if (raw == null) {
      _items = seedProPlayers.map((p) => p.copyWith()).toList();
    } else {
      try {
        _items = raw.map(ProPlayer.fromJson).toList();
      } catch (_) {
        _items = seedProPlayers.map((p) => p.copyWith()).toList();
      }
    }
    _nextId = _items.fold<int>(0, (m, p) => p.id > m ? p.id : m) + 1;
    _persist();
  }

  Future<void> _persist() =>
      _store.writeList(_key, _items.map((e) => e.toJson()).toList());

  @override
  Future<PageResult<ProPlayer>> find(ProPlayerQuery q) async {
    var rows = _items.where((p) => q.includeDeleted || !p.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (p) =>
                p.nickname.toLowerCase().contains(needle) ||
                p.realName.toLowerCase().contains(needle) ||
                p.team.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.country != null && q.country!.isNotEmpty) {
      rows = rows.where((p) => p.country == q.country).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'realName' => a.realName.toLowerCase().compareTo(b.realName.toLowerCase()),
        'team' => a.team.toLowerCase().compareTo(b.team.toLowerCase()),
        'rating' => a.rating.compareTo(b.rating),
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        _ => a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    return paginate(rows, page: q.page, size: q.size);
  }

  @override
  Future<ProPlayer?> findById(int id) async {
    for (final p in _items) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<ProPlayer> create(ProPlayer player) async {
    final created = player.copyWith(id: _nextId++);
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<ProPlayer> update(ProPlayer player) async {
    final i = _items.indexWhere((p) => p.id == player.id);
    if (i == -1) throw StateError('Про-игрок ${player.id} не найден');
    _items[i] = player;
    await _persist();
    return player;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Про-игрок $id не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((p) => p.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Про-игрок $id не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> softDeleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<int> hardDeleteMany(List<int> ids) async {
    final before = _items.length;
    _items.removeWhere((p) => ids.contains(p.id));
    await _persist();
    return before - _items.length;
  }

  @override
  Future<int> restoreMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((p) => p.id == id && p.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(clearDeletedAt: true);
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<List<ProPlayer>> allActive() async =>
      _items.where((p) => !p.isDeleted).toList();
}
