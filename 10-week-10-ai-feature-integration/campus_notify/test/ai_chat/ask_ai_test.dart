import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'package:campus_notify/features/ai_chat/domain/usecases/ask_ai.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repository PALSU — use case diuji murni, tanpa Dio/secure storage.
class FakeAiChatRepository implements AiChatRepository {
  FakeAiChatRepository({this.lastQuestion, this.answer = 'Jawaban palsu'});

  String? lastQuestion;
  final String answer;

  @override
  Future<({String? answer, bool isFallback, Failure? failure})> ask({
    required String question,
  }) async {
    lastQuestion = question;
    return (answer: answer, isFallback: false, failure: null);
  }
}

void main() {
  group('AskAi — aturan bisnis sebelum API dipanggil', () {
    test('pertanyaan kosong ditolak tanpa memanggil repository', () async {
      final repo = FakeAiChatRepository();
      final usecase = AskAi(repo);

      final result = await usecase(question: '   ');

      expect(result.answer, isNull);
      expect(result.failure, isA<ValidationFailure>());
      expect(repo.lastQuestion, isNull, reason: 'repository tidak boleh dipanggil');
    });

    test('pertanyaan melebihi batas panjang ditolak', () async {
      final repo = FakeAiChatRepository();
      final usecase = AskAi(repo);

      final result = await usecase(question: 'a' * (AskAi.maxQuestionLength + 1));

      expect(result.answer, isNull);
      expect(result.failure, isA<ValidationFailure>());
      expect(repo.lastQuestion, isNull);
    });

    test('pertanyaan valid diteruskan setelah di-trim', () async {
      final repo = FakeAiChatRepository();
      final usecase = AskAi(repo);

      final result = await usecase(question: '  kapan jadwal UTS?  ');

      expect(repo.lastQuestion, 'kapan jadwal UTS?');
      expect(result.answer, 'Jawaban palsu');
      expect(result.failure, isNull);
    });
  });
}
