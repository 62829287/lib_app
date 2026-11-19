import 'auth_role.dart';

class AuthUser {
  final String id;
  final String username;
  final String displayName;
  final AuthRole role;

  const AuthUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'displayName': displayName,
    'role': role.key,
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: '${json['id'] ?? ''}',
    username:
        json['username'] as String? ?? json['email'] as String? ?? '',
    displayName:
        json['displayName'] as String? ??
        json['name'] as String? ??
        json['username'] as String? ??
        '',
    role: AuthRole.fromKey(json['role'] as String?),
  );

  factory AuthUser.fromPb(Map<String, dynamic> record) => AuthUser(
    id: '${record['id'] ?? ''}',
    username: record['username'] as String? ?? record['email'] as String? ?? '',
    displayName:
        record['name'] as String? ??
        record['username'] as String? ??
        record['email'] as String? ??
        '',
    role: AuthRole.fromKey(record['role'] as String?),
  );
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthTokens.fromPb(Map<String, dynamic> json) {
    final token = json['token'] as String? ?? '';
    final record = Map<String, dynamic>.from(json['record'] as Map? ?? const {});
    return AuthTokens(
      accessToken: token,
      refreshToken: token,
      user: AuthUser.fromPb(record),
    );
  }

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('token') && json.containsKey('record')) {
      return AuthTokens.fromPb(json);
    }
    return AuthTokens(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      user: AuthUser.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      ),
    );
  }
}
