import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/auth_user.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthTokens> login(String username, String password) => guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/collections/users/auth-with-password',
      data: {'identity': username.trim(), 'password': password},
    );
    return AuthTokens.fromPb(response.data!);
  });

  Future<AuthTokens> register({
    required String username,
    required String displayName,
    required String password,
  }) => guard(() async {
    final email = username.contains('@')
        ? username.trim()
        : '${username.trim()}@dota.local';
    await _dio.post<Map<String, dynamic>>(
      '/api/collections/users/records',
      data: {
        'email': email,
        'username': username.trim(),
        'name': displayName.trim(),
        'password': password,
        'passwordConfirm': password,
        'role': 'viewer',
        'emailVisibility': true,
      },
    );
    return login(username.trim(), password);
  });

  Future<AuthUser> me() => guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/collections/users/auth-refresh',
    );
    final record = Map<String, dynamic>.from(
      response.data?['record'] as Map? ?? const {},
    );
    return AuthUser.fromPb(record);
  });

  Future<AuthTokens> refresh(String refreshToken) => guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/collections/users/auth-refresh',
      options: Options(headers: {'Authorization': refreshToken}),
    );
    return AuthTokens.fromPb(response.data!);
  });

  Future<List<AuthUser>> listAccounts({String search = ''}) => guard(() async {
    final q = search.trim();
    final filter = q.isEmpty
        ? null
        : '(username ~ "${q.replaceAll('"', '')}" || email ~ "${q.replaceAll('"', '')}" || name ~ "${q.replaceAll('"', '')}")';
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/collections/users/records',
      queryParameters: {
        'perPage': 200,
        if (filter != null) 'filter': filter,
        'sort': 'username',
      },
    );
    return (response.data?['items'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => AuthUser.fromPb(Map<String, dynamic>.from(e)))
        .toList();
  });

  Future<AuthUser> updateAccountRole(String id, String role) =>
      guard(() async {
        final response = await _dio.patch<Map<String, dynamic>>(
          '/api/collections/users/records/$id',
          data: {'role': role},
        );
        return AuthUser.fromPb(response.data!);
      });
}
