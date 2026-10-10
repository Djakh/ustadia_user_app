import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/word_forge/word_forge.dart';

/// Answers every request with one canned response and records the request.
class _Server implements HttpClientAdapter {
  int status = 200;
  Object? body;
  bool down = false;
  RequestOptions? request;
  Object? sent;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    request = options;
    sent = options.data;
    if (down) throw DioException.connectionError(requestOptions: options, reason: 'no route');
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _serverCopy = {
  'slot': 1,
  'revision': 16,
  'schemaVersion': 4,
  'contentHash': 'c01d9e77b2',
  'summary': {'level': 8, 'xp': 2010, 'lastPlayedAt': 1791400500000},
  'data': {'version': 4, 'xp': 2010},
  'deviceId': '0e9a7c55',
  'clientUpdatedAt': 1791400500000,
  'updatedAt': '2026-10-08T10:04:58.770Z',
};

void main() {
  late _Server server;
  late DioWordForgeCloud cloud;

  setUp(() {
    server = _Server();
    final dio = Dio(BaseOptions(baseUrl: 'https://dev.backend.ustadia.com'))..httpClientAdapter = server;
    cloud = DioWordForgeCloud(dio: dio, deviceId: 'device-1', appVersion: '1.2.3');
  });

  CloudWrite write() => const CloudWrite(
        baseRevision: 14,
        schemaVersion: 4,
        contentHash: '4be7d0c39a',
        clientUpdatedAt: 1791400123456,
        summary: {'xp': 1905},
        data: {'version': 4, 'xp': 1905},
      );

  group('DioWordForgeCloud (backend doc responses)', () {
    test('list: slots, revisions and lastPlayedSlot', () async {
      server.body = {
        'data': [
          {
            'slot': 1,
            'revision': 14,
            'schemaVersion': 4,
            'summary': {'xp': 1840, 'lastPlayedAt': 1791400000000},
            'sizeBytes': 23817,
            'deviceId': 'x',
            'clientUpdatedAt': 1791400000000,
            'updatedAt': '2026-10-08T09:41:12.512Z',
          },
        ],
        'lastPlayedSlot': 1,
        'serverTime': '2026-10-08T10:02:44.130Z',
      };
      final list = await cloud.listSlots();
      expect(server.request!.method, 'GET');
      expect(server.request!.path, '/students/word-forge/saves');
      expect(server.request!.headers['X-Device-Id'], 'device-1');
      expect(server.request!.headers['X-App-Version'], '1.2.3');
      expect(server.request!.extra['skipUnauthorizedLogout'], isTrue, reason: 'a sync 401 must not log out');
      expect(list.slots.single.slot, 1);
      expect(list.slots.single.revision, 14);
      expect(list.slots.single.lastPlayedAt, 1791400000000);
      expect(list.lastPlayedSlot, 1);
    });

    test('list: nothing synced yet', () async {
      server.body = {'data': <Object>[], 'lastPlayedSlot': null, 'serverTime': '2026-10-08T10:02:44.130Z'};
      final list = await cloud.listSlots();
      expect(list.slots, isEmpty);
      expect(list.lastPlayedSlot, isNull);
    });

    test('get: full slot; 404 SLOT_EMPTY is an empty slot', () async {
      server.body = _serverCopy;
      final save = await cloud.getSlot(1);
      expect(server.request!.path, '/students/word-forge/saves/1');
      expect(save!.revision, 16);
      expect(save.contentHash, 'c01d9e77b2');
      expect(save.data['xp'], 2010);

      server
        ..status = 404
        ..body = {'statusCode': 404, 'code': 'SLOT_EMPTY', 'message': 'Slot 2 is empty.'};
      expect(await cloud.getSlot(2), isNull);
    });

    test('put: sends the documented body and returns the new revision (201 and 200)', () async {
      server
        ..status = 201
        ..body = {'slot': 1, 'revision': 1, 'schemaVersion': 4, 'contentHash': '4be7d0c39a', 'updatedAt': 'x'};
      final created = await cloud.putSlot(1, write());
      expect(server.request!.method, 'PUT');
      expect(server.request!.path, '/students/word-forge/saves/1');
      expect(server.sent, {
        'baseRevision': 14,
        'schemaVersion': 4,
        'contentHash': '4be7d0c39a',
        'clientUpdatedAt': 1791400123456,
        'summary': {'xp': 1905},
        'data': {'version': 4, 'xp': 1905},
      });
      expect((created as CloudWriteSaved).revision, 1);

      server
        ..status = 200
        ..body = {'slot': 1, 'revision': 15, 'schemaVersion': 4, 'contentHash': '4be7d0c39a', 'updatedAt': 'x'};
      expect((await cloud.putSlot(1, write()) as CloudWriteSaved).revision, 15);
    });

    test('put: 409 brings the server copy, or null when the slot is gone', () async {
      server
        ..status = 409
        ..body = {
          'statusCode': 409,
          'code': 'REVISION_CONFLICT',
          'message': 'Slot 1 was changed on another device.',
          'server': _serverCopy,
        };
      final conflict = await cloud.putSlot(1, write()) as CloudWriteConflict;
      expect(conflict.server!.revision, 16);
      expect(conflict.server!.data['xp'], 2010);

      server.body = {'statusCode': 409, 'code': 'REVISION_CONFLICT', 'message': 'gone', 'server': null};
      expect((await cloud.putSlot(1, write()) as CloudWriteConflict).server, isNull);
    });

    test('delete: 204 deleted, 404 not found, 409 conflict; revision in the query', () async {
      server
        ..status = 204
        ..body = null;
      expect(await cloud.deleteSlot(1, 15), CloudDeleteResult.deleted);
      expect(server.request!.method, 'DELETE');
      expect(server.request!.uri.toString(), endsWith('/students/word-forge/saves/1?revision=15'));

      server
        ..status = 404
        ..body = {'statusCode': 404, 'code': 'SLOT_EMPTY', 'message': 'empty'};
      expect(await cloud.deleteSlot(1, 15), CloudDeleteResult.notFound);

      server
        ..status = 409
        ..body = {'statusCode': 409, 'code': 'REVISION_CONFLICT', 'message': 'changed', 'server': _serverCopy};
      expect(await cloud.deleteSlot(1, 15), CloudDeleteResult.conflict);
    });

    test('offline, 401, 429, 5xx and an undeployed route all mean "try later"', () async {
      final failures = <(int, Object?)>[
        (401, {'statusCode': 401, 'code': 'UNAUTHORIZED', 'message': 'expired'}),
        (403, {'statusCode': 403, 'code': 'FORBIDDEN', 'message': 'not a student'}),
        (413, {'statusCode': 413, 'code': 'PAYLOAD_TOO_LARGE', 'message': 'too big'}),
        (429, {'statusCode': 429, 'code': 'RATE_LIMITED', 'message': 'slow down'}),
        (500, {'statusCode': 500, 'code': 'SERVER_ERROR', 'message': 'oops'}),
        (404, {'statusCode': 404, 'message': 'Cannot GET /students/word-forge/saves/1'}),
      ];
      for (final (status, body) in failures) {
        server
          ..status = status
          ..body = body;
        await expectLater(cloud.listSlots(), throwsA(isA<WordForgeCloudUnavailable>()), reason: 'list $status');
        await expectLater(cloud.getSlot(1), throwsA(isA<WordForgeCloudUnavailable>()), reason: 'get $status');
        await expectLater(cloud.putSlot(1, write()), throwsA(isA<WordForgeCloudUnavailable>()), reason: 'put $status');
      }
      server.down = true;
      await expectLater(cloud.listSlots(), throwsA(isA<WordForgeCloudUnavailable>()));
      await expectLater(cloud.deleteSlot(1, 1), throwsA(isA<WordForgeCloudUnavailable>()));
    });
  });
}
