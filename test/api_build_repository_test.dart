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
  id: '',
  title: 'Dup',
  code: 'PA-BF-736A',
  patch: '7.41c',
  difficulty: 1,
  heroId: 'h1',
  proPlayerIds: [],
  roleIds: [],
  picks: 0,
  wins: 0,
);

void main() {
  group('Репозиторий сборок', () {
    test('find разбирает страницу сборок', () async {
      final dio = _dioWith((options) async {
        expect(options.path, '/api/collections/builds/records');
        expect(options.queryParameters['page'], 1);
        return _json(200, {
          'items': [
            {
              'id': 'b1',
              'title': 'PA BF',
              'code': 'PA-BF',
              'patch': '7.41c',
              'difficulty': 3,
              'heroId': 'h1',
              'proPlayerIds': ['p1'],
              'roleIds': ['r1'],
              'picks': 10,
              'wins': 5,
            },
          ],
          'page': 1,
          'perPage': 10,
          'totalItems': 1,
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
            'ошибка поля code',
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
        () => ApiBuildRepository(dio).hardDelete('b1'),
        throwsA(
          isA<ConflictException>().having(
            (e) => e.message,
            'message',
            contains('связанные'),
          ),
        ),
      );
    });

    test('недоступность сервера на create даёт NetworkException', () async {
      final dio = _dioWith((_) async {
        throw DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        );
      });

      expect(
        () => ApiBuildRepository(dio).create(_sampleBuild),
        throwsA(isA<NetworkException>()),
      );
    });

    test('softDelete вызывает PATCH deletedAt', () async {
      var patched = false;
      final dio = _dioWith((options) async {
        expect(options.method, 'PATCH');
        expect(options.path, '/api/collections/builds/records/b7');
        expect(options.data['deletedAt'], isNotNull);
        patched = true;
        return _json(200, {'id': 'b7'});
      });

      await ApiBuildRepository(dio).softDelete('b7');
      expect(patched, isTrue);
    });
  });
}
