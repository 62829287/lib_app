import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import '../models/auth_role.dart';
import '../models/auth_user.dart';
import '../repositories/auth_api.dart';

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUser = 'auth_user_json';
  static const _kSessionStarted = 'auth_session_started';

  static const sessionMaxDuration = Duration(hours: 8);
  static const inactivityTimeout = Duration(minutes: 3);
  static const inactivityWarning = Duration(seconds: 30);

  AuthNotifier(this._prefs, this._api);

  final SharedPreferences _prefs;
  final AuthApi _api;

  AuthUser? _user;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _sessionStartedAt;
  bool _refreshing = false;

  AuthUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null;
  DateTime? get sessionStartedAt => _sessionStartedAt;
  bool get isRefreshing => _refreshing;

  bool has(AuthRole role) => _user != null && _user!.role.atLeast(role);

  bool canBrowsePros() =>
      _user != null && Permissions.canBrowsePros(_user!.role);

  bool canBrowseReferenceData() =>
      _user != null && Permissions.canBrowseReferenceData(_user!.role);

  bool canEditCatalog() =>
      _user != null && Permissions.canEditCatalog(_user!.role);

  bool canHardDelete() =>
      _user != null && Permissions.canHardDelete(_user!.role);

  bool canManageUsers() =>
      _user != null && Permissions.canManageUsers(_user!.role);

  bool get isSessionExpired {
    final started = _sessionStartedAt;
    if (started == null) return false;
    return DateTime.now().difference(started) > sessionMaxDuration;
  }

  Future<void> restore() async {
    final access = _prefs.getString(_kAccess);
    final refresh = _prefs.getString(_kRefresh);
    final userRaw = _prefs.getString(_kUser);
    final startedRaw = _prefs.getString(_kSessionStarted);

    if (access == null) return;

    _accessToken = access;
    _refreshToken = refresh;
    if (userRaw != null && userRaw.isNotEmpty) {
      try {
        _user = AuthUser.fromJson(
          Map<String, dynamic>.from(jsonDecode(userRaw) as Map),
        );
      } catch (_) {}
    }
    if (startedRaw != null) {
      _sessionStartedAt = DateTime.tryParse(startedRaw);
    }

    if (_sessionStartedAt != null &&
        DateTime.now().difference(_sessionStartedAt!) > sessionMaxDuration) {
      await logout();
      return;
    }

    try {
      final serverUser = await _api.me();
      if (_user == null) {
        _user = serverUser;
        await _persistUser(serverUser);
      }
    } on UnauthorizedException {
      if (refresh != null) {
        try {
          await refreshTokens();
        } catch (_) {
          await logout();
        }
      } else {
        await logout();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final result = await _api.login(username.trim(), password);
    await _applySession(result);
  }

  Future<void> register({
    required String username,
    required String displayName,
    required String password,
  }) async {
    final result = await _api.register(
      username: username.trim(),
      displayName: displayName.trim(),
      password: password,
    );
    await _applySession(result);
  }

  Future<void> refreshTokens() async {
    if (_refreshing) {
      while (_refreshing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (_accessToken == null) throw const UnauthorizedException();
      return;
    }
    final refresh = _refreshToken ?? _prefs.getString(_kRefresh);
    if (refresh == null || refresh.isEmpty) {
      throw const UnauthorizedException();
    }
    _refreshing = true;
    try {
      final result = await _api.refresh(refresh);
      await _applySession(result, keepSessionStart: true);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> applyLocalUser(AuthUser user) async {
    _user = user;
    await _persistUser(user);
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _sessionStartedAt = null;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kUser);
    await _prefs.remove(_kSessionStarted);
    notifyListeners();
  }

  Future<void> _applySession(
    AuthTokens result, {
    bool keepSessionStart = false,
  }) async {
    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _user = result.user;
    if (!keepSessionStart || _sessionStartedAt == null) {
      _sessionStartedAt = DateTime.now();
    }
    await _prefs.setString(_kAccess, result.accessToken);
    await _prefs.setString(_kRefresh, result.refreshToken);
    await _persistUser(result.user);
    await _prefs.setString(
      _kSessionStarted,
      _sessionStartedAt!.toIso8601String(),
    );
    notifyListeners();
  }

  Future<void> _persistUser(AuthUser user) async {
    await _prefs.setString(_kUser, jsonEncode(user.toJson()));
  }
}
