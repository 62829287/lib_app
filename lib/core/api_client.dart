import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio({String? Function()? tokenProvider}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kIsWeb) {
          final qp = Uri.base.queryParameters;
          if (qp.containsKey('__fail')) {
            options.queryParameters = {
              ...options.queryParameters,
              '__fail': qp['__fail']!,
            };
          }
          if (qp.containsKey('__delay')) {
            options.queryParameters = {
              ...options.queryParameters,
              '__delay': qp['__delay']!,
            };
          }
        }
        if (kDebugMode) {
          debugPrint(
            '[API] → ${options.method} ${options.uri}',
          );
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
            '[API] ← ${response.statusCode} ${response.requestOptions.method} '
            '${response.requestOptions.uri}',
          );
        }
        final status = response.statusCode ?? 0;
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint(
            '[API] сбой ${error.requestOptions.method} '
            '${error.requestOptions.uri}: ${error.type}',
          );
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
}

Future<T> guardRead<T>(Future<T> Function() action) async {
  const delays = [
    Duration(milliseconds: 300),
    Duration(milliseconds: 800),
    Duration(milliseconds: 1600),
  ];

  Object? lastError;
  for (var attempt = 0; attempt <= delays.length; attempt++) {
    try {
      return await guard(action);
    } on RequestCancelledException {
      rethrow;
    } on NetworkException catch (e) {
      lastError = e;
      if (attempt == delays.length) rethrow;
      await Future<void>.delayed(delays[attempt]);
    } on ServerException catch (e) {
      lastError = e;
      if (attempt == delays.length) rethrow;
      await Future<void>.delayed(delays[attempt]);
    }
  }
  throw lastError ?? const ServerException();
}
