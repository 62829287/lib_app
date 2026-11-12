import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class JsonStore {
  JsonStore(this._prefs);

  final SharedPreferences _prefs;

  static const dataVersion = 2;
  static const versionKey = 'dota_data_version';

  bool ensureVersion() {
    final current = _prefs.getInt(versionKey) ?? 0;
    if (current == dataVersion) return false;

    for (final key in [
      'builds_v1',
      'pro_players_v1',
      'roles_v1',
      'heroes_v1',
      'users_v1',
    ]) {
      _prefs.remove(key);
    }
    _prefs.setInt(versionKey, dataVersion);
    return true;
  }

  List<Map<String, dynamic>>? readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> items) async {
    await _prefs.setString(key, jsonEncode(items));
  }
}
