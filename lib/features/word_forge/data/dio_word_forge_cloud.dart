import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/word_forge_cloud.dart';

/// [WordForgeCloud] over the host app's authenticated Dio.
///
/// * GETs bypass the host's response cache: a slot must never be read stale.
/// * A 401 here never logs the user out (`skipUnauthorizedLogout`): a
///   background game sync must not end the session; it just reports the
///   cloud as unavailable.
/// * A 404 without the API's `SLOT_EMPTY` code means the endpoint is not
///   deployed on this server: unavailable, not "empty".
class DioWordForgeCloud implements WordForgeCloud {
  static const String basePath = '/students/word-forge/saves';

  final Dio dio;
  final String deviceId;
  final String? appVersion;

  DioWordForgeCloud({required this.dio, required this.deviceId, this.appVersion});

  static final CacheOptions _noCache = CacheOptions(store: MemCacheStore(), policy: CachePolicy.noCache);

  Options _options({bool read = false}) {
    final base = read ? _noCache.toOptions() : Options();
    return base.copyWith(
      headers: {
        'X-Device-Id': deviceId,
        if (appVersion != null) 'X-App-Version': appVersion,
      },
      extra: {...?base.extra, 'skipUnauthorizedLogout': true},
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    );
  }

  @override
  Future<CloudSlotList> listSlots() async {
    final Response<Object?> response;
    try {
      response = await _send(() => dio.get<Object?>(basePath, options: _options(read: true)));
    } on _ApiError catch (error) {
      throw error.unavailable;
    }
    final body = _map(response.data);
    final items = body['data'] is List ? body['data'] as List : const [];
    return CloudSlotList(
      slots: [
        for (final item in items)
          if (item is Map)
            CloudSlotSummary(
              slot: _int(item['slot']),
              revision: _int(item['revision']),
              schemaVersion: _int(item['schemaVersion']),
              lastPlayedAt: item['summary'] is Map ? _intOrNull((item['summary'] as Map)['lastPlayedAt']) : null,
            ),
      ],
      lastPlayedSlot: _intOrNull(body['lastPlayedSlot']),
    );
  }

  @override
  Future<CloudSave?> getSlot(int slot) async {
    try {
      final response = await _send(() => dio.get<Object?>('$basePath/$slot', options: _options(read: true)));
      return _save(_map(response.data));
    } on _ApiError catch (error) {
      if (error.status == 404 && error.code == 'SLOT_EMPTY') return null;
      throw error.unavailable;
    }
  }

  @override
  Future<CloudWriteResult> putSlot(int slot, CloudWrite write) async {
    try {
      final response = await _send(() => dio.put<Object?>(
            '$basePath/$slot',
            data: {
              'baseRevision': write.baseRevision,
              'schemaVersion': write.schemaVersion,
              'contentHash': write.contentHash,
              'clientUpdatedAt': write.clientUpdatedAt,
              'summary': write.summary,
              'data': write.data,
            },
            options: _options(),
          ));
      return CloudWriteSaved(_int(_map(response.data)['revision']));
    } on _ApiError catch (error) {
      if (error.status == 409 && error.code == 'REVISION_CONFLICT') {
        final server = error.body['server'];
        return CloudWriteConflict(server is Map ? _save(Map<String, dynamic>.from(server)) : null);
      }
      throw error.unavailable;
    }
  }

  @override
  Future<CloudDeleteResult> deleteSlot(int slot, int revision) async {
    try {
      await _send(() => dio.delete<Object?>('$basePath/$slot',
          queryParameters: {'revision': revision}, options: _options()));
      return CloudDeleteResult.deleted;
    } on _ApiError catch (error) {
      if (error.status == 404 && error.code == 'SLOT_EMPTY') return CloudDeleteResult.notFound;
      if (error.status == 409 && error.code == 'REVISION_CONFLICT') return CloudDeleteResult.conflict;
      throw error.unavailable;
    }
  }

  /// Runs a request; HTTP errors become [_ApiError], transport errors
  /// become [WordForgeCloudUnavailable].
  Future<Response<Object?>> _send(Future<Response<Object?>> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      final response = error.response;
      if (response == null) throw WordForgeCloudUnavailable('network: ${error.type.name}');
      final body = response.data is Map ? Map<String, dynamic>.from(response.data as Map) : <String, dynamic>{};
      final apiError = _ApiError(response.statusCode ?? 0, body);
      if (kDebugMode && apiError.status != 404 && apiError.status != 409) {
        debugPrint('[WordForge cloud] HTTP ${apiError.status} ${apiError.code ?? ''}: ${body['message'] ?? ''}');
      }
      throw apiError;
    }
  }

  CloudSave _save(Map<String, dynamic> json) => CloudSave(
        slot: _int(json['slot']),
        revision: _int(json['revision']),
        schemaVersion: _int(json['schemaVersion']),
        contentHash: json['contentHash']?.toString() ?? '',
        data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : const {},
      );

  static Map<String, dynamic> _map(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const WordForgeCloudUnavailable('unexpected response body');
  }

  static int _int(Object? value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  static int? _intOrNull(Object? value) => value is num ? value.toInt() : int.tryParse('${value ?? ''}');

  /// Stable random id of this installation, sent as `X-Device-Id`.
  static String deviceIdFrom(SharedPreferences preferences) {
    const key = 'word_forge.device_id';
    final existing = preferences.getString(key);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final id = List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
    preferences.setString(key, id);
    return id;
  }
}

class _ApiError implements Exception {
  final int status;
  final Map<String, dynamic> body;

  _ApiError(this.status, this.body);

  String? get code => body['code']?.toString();

  WordForgeCloudUnavailable get unavailable => WordForgeCloudUnavailable('HTTP $status ${code ?? ''}'.trim());
}
