import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/core/api_client.dart';
import 'package:library_app/core/api_exceptions.dart';
import 'package:library_app/models/build.dart';
import 'package:library_app/models/build_query.dart';
import 'package:library_app/repositories/api_build_repository.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }
}

Dio _dioWith(Future<ResponseBody> Function(RequestOptions) handler) {
  final dio = buildDio();
  dio.httpClientAdapter = _ScriptedAdapter(handler);
  return dio;
}

ResponseBody _json(int status, Object? data) {
  return ResponseBody.fromString(
    data == null ? '' : jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

const _sampleBuild = Build(
  id: 0,
  title: 'Dup',
  code: 'PA-BF-736A',
  patch: '7.41c',
  difficulty: 1,
  heroId: 1,
  proPlayerIds: [],
  roleIds: [],
  picks: 0,
  wins: 0,
);

void main() {
  test('find разбирает страницу сборок', () async {
    final dio = _dioWith((options) async {
      expect(options.path, '/builds');
      expect(options.queryParameters['page'], 1);
      return _json(200, {
        'items': [
          {
            'id': 1,
            'title': 'PA BF',
            'code': 'PA-BF',
            'patch': '7.41c',
            'difficulty': 3,
            'heroId': 1,
            'proPlayerIds': [1],
            'roleIds': [1],
            'picks': 10,
            'wins': 5,
          }
        ],
        'page': 1,
        'size': 10,
        'total': 1,
      });
    });

    final page = await ApiBuildRepository(dio).find(const BuildQuery());
    expect(page.total, 1);
    expect(page.items.single.code, 'PA-BF');
  });

  test('create при 422 бросает ValidationException с полями', () async {
    final dio = _dioWith((_) async {
      return _json(422, {
        'message': 'Ошибка валидации',
        'errors': {'code': 'Код уже используется'},
      });
    });

    expect(
      () => ApiBuildRepository(dio).create(_sampleBuild),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.errors['code'],
          'code error',
          'Код уже используется',
        ),
      ),
    );
  });

  test('hardDelete при 409 бросает ConflictException', () async {
    final dio = _dioWith((_) async {
      return _json(409, {
        'message': 'Нельзя удалить: есть связанные сборки.',
      });
    });

    expect(
      () => ApiBuildRepository(dio).hardDelete(1),
      throwsA(
        isA<ConflictException>().having(
          (e) => e.message,
          'message',
          contains('связанные'),
        ),
      ),
    );
  });

  test('недоступность сервера на create → NetworkException', () async {
    final dio = _dioWith((options) async {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'Connection refused',
      );
    });

    expect(
      () => ApiBuildRepository(dio).create(_sampleBuild),
      throwsA(isA<NetworkException>()),
    );
  });

  test('softDelete вызывает DELETE без hard', () async {
    RequestOptions? seen;
    final dio = _dioWith((options) async {
      seen = options;
      return ResponseBody.fromString('', 204);
    });

    await ApiBuildRepository(dio).softDelete(7);
    expect(seen?.method, 'DELETE');
    expect(seen?.path, '/builds/7');
    expect(seen?.queryParameters.containsKey('hard'), isFalse);
  });

  test('mapHttpError 422 собирает errors', () {
    final err = mapHttpError(422, {
      'message': 'Ошибка валидации',
      'errors': {'code': 'занят'},
    });
    expect(err, isA<ValidationException>());
    expect((err as ValidationException).errors['code'], 'занят');
  });
}
