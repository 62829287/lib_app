import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/pb.dart';

import 'data_export_download_stub.dart'
    if (dart.library.html) 'data_export_download_web.dart' as download;

class DataExportService {
  DataExportService(this._dio);

  final Dio _dio;

  static const _collections = <String>[
    'teams',
    'roles',
    'heroes',
    'pro_players',
    'builds',
    'app_users',
    'users',
  ];

  Future<Map<String, dynamic>> exportAll() async {
    final collections = <String, dynamic>{};
    for (final name in _collections) {
      collections[name] = await _fetchCollection(name);
    }
    return {
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'collections': collections,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchCollection(String collection) async {
    final items = <Map<String, dynamic>>[];
    var page = 1;
    const perPage = 200;

    while (true) {
      final response = await _dio.get<Map<String, dynamic>>(
        pbRecords(collection),
        queryParameters: {'page': page, 'perPage': perPage},
      );
      final data = response.data ?? const <String, dynamic>{};
      final batch = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      items.addAll(batch);

      final totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
      if (page >= totalPages) break;
      page++;
    }
    return items;
  }

  Future<void> downloadJson(
    Map<String, dynamic> payload, {
    String filename = 'dota-export.json',
  }) async {
    final json = const JsonEncoder.withIndent('  ').convert(payload);
    if (!kIsWeb) {
      throw UnsupportedError('Скачивание JSON доступно только в веб-сборке');
    }
    final bytes = utf8.encode(json);
    download.triggerJsonDownload(bytes, filename);
  }
}