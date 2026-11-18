import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/auth_user.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthTokens> login(String username, String password) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {'username': username, 'password': password},
        );
        return AuthTokens.fromJson(response.data!);
      });

  Future<AuthTokens> register({
    required String username,
    required String displayName,
    required String password,
  }) =>
      guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/auth/register',
          data: {
            'username': username,
            'displayName': displayName,
            'password': password,
          },
        );
        return AuthTokens.fromJson(response.data!);
      });

  Future<AuthUser> me() => guard(() async {
        final response = await _dio.get<Map<String, dynamic>>('/auth/me');
        return AuthUser.fromJson(response.data!);
      });

  Future<AuthTokens> refresh(String refreshToken) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );
        return AuthTokens.fromJson(response.data!);
      });

  Future<List<AuthUser>> listAccounts({String search = ''}) => guard(() async {
        final response = await _dio.get<List<dynamic>>(
          '/accounts',
          queryParameters: {
            if (search.trim().isNotEmpty) 'search': search.trim(),
          },
        );
        return (response.data ?? [])
            .map((e) => AuthUser.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      });

  Future<AuthUser> updateAccountRole(int id, String role) => guard(() async {
        final response = await _dio.patch<Map<String, dynamic>>(
          '/accounts/$id',
          data: {'role': role},
        );
        return AuthUser.fromJson(response.data!);
      });
}
