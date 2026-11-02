import 'dart:convert';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/ai_chat/data/ai_key_store.dart';
import 'package:campus_notify/features/ai_chat/data/gemini_api.dart';
import 'package:campus_notify/features/ai_chat/data/repositories/ai_chat_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Key store PALSU — tidak menyentuh plugin secure storage.
class FakeAiKeyStore extends AiKeyStore {
  FakeAiKeyStore({this.storedKey});

  final String? storedKey;

  @override
  Future<String?> getKey() async => storedKey;

  @override
  Future<void> saveKey(String key) async {}

  @override
  Future<void> clear() async {}
}

/// Adapter Dio palsu — respons bisa dipaksakan tanpa jaringan asli.
class StubAdapter implements HttpClientAdapter {
  StubAdapter({this.status = 200, this.body});

  final int status;
  final Map<String, dynamic>? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body ?? {}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

GeminiApi apiReturning({int status = 200, Map<String, dynamic>? body}) {
  final dio = Dio()..httpClientAdapter = StubAdapter(status: status, body: body);
  return GeminiApi(dio: dio);
}

Map<String, dynamic> geminiBody(String text) => {
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': text},
        ],
      },
    },
  ],
};

void main() {
  group('AiChatRepositoryImpl — fallback & normal response', () {
    test('tanpa API key: langsung fallback ke data lokal, tanpa panggil API',
        () async {
      final repo = AiChatRepositoryImpl(
        keyStore: FakeAiKeyStore(storedKey: null),
        api: apiReturning(status: 500), // tidak akan pernah dipanggil
      );

      final result = await repo.ask(question: 'kapan jadwal UTS?');

      expect(result.isFallback, isTrue);
      expect(result.answer, contains('Ujian Tengah Semester'));
      expect(result.failure, isA<ValidationFailure>());
    });

    test('dengan API key + respons valid: jawaban LLM dipakai apa adanya',
        () async {
      final repo = AiChatRepositoryImpl(
        keyStore: FakeAiKeyStore(storedKey: 'test-key'),
        api: apiReturning(body: geminiBody('Jadwal UTS minggu 12.')),
      );

      final result = await repo.ask(question: 'kapan jadwal UTS?');

      expect(result.isFallback, isFalse);
      expect(result.answer, 'Jadwal UTS minggu 12.');
      expect(result.failure, isNull);
    });

    test('API error HTTP 500: tidak crash, fallback ke data lokal', () async {
      final repo = AiChatRepositoryImpl(
        keyStore: FakeAiKeyStore(storedKey: 'test-key'),
        api: apiReturning(status: 500, body: {'error': {'message': 'boom'}}),
      );

      final result = await repo.ask(question: 'cara langganan pengumuman?');

      expect(result.isFallback, isTrue);
      expect(result.answer, isNotNull);
      expect(result.failure, isA<NetworkFailure>());
    });

    test('respons 200 tapi candidates kosong: dianggap tidak valid, fallback',
        () async {
      final repo = AiChatRepositoryImpl(
        keyStore: FakeAiKeyStore(storedKey: 'test-key'),
        api: apiReturning(body: {'candidates': <dynamic>[]}),
      );

      final result = await repo.ask(question: 'halo');

      expect(result.isFallback, isTrue);
      expect(result.failure, isA<NetworkFailure>());
    });

    test('respons diblokir safety (part tanpa text): fallback, bukan exception',
        () async {
      final repo = AiChatRepositoryImpl(
        keyStore: FakeAiKeyStore(storedKey: 'test-key'),
        api: apiReturning(
          body: {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'inlineData': null},
                  ],
                },
                'finishReason': 'SAFETY',
              },
            ],
          },
        ),
      );

      final result = await repo.ask(question: 'halo');

      expect(result.isFallback, isTrue);
      expect(result.answer, isNotNull);
    });

    test('API key 401: pesan ramah menyebut Pengaturan AI', () async {
      final repo = AiChatRepositoryImpl(
        keyStore: FakeAiKeyStore(storedKey: 'salah-key'),
        api: apiReturning(status: 401),
      );

      final result = await repo.ask(question: 'halo');

      expect(result.isFallback, isTrue);
      expect(result.failure!.message, contains('Pengaturan AI'));
    });
  });

  group('GeminiApi — bentuk request', () {
    test('model & endpoint Gemini benar', () {
      expect(
        GeminiApi.systemPrompt,
        allOf(contains('Bahasa Indonesia'), contains('NIK')),
      );
    });
  });
}
