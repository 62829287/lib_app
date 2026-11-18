import 'auth_role.dart';

class AuthUser {
  final int id;
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
        id: (json['id'] as num?)?.toInt() ?? 0,
        username: json['username'] as String? ?? '',
        displayName: json['displayName'] as String? ??
            json['username'] as String? ??
            '',
        role: AuthRole.fromKey(json['role'] as String?),
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

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        user: AuthUser.fromJson(
          Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
        ),
      );
}
