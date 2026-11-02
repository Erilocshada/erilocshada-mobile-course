import '../../../../core/failures.dart';
import '../repositories/ai_chat_repository.dart';

/// Use case: satu operasi — tanyakan pertanyaan ke asisten AI,
/// dengan aturan bisnis validasi input sebelum menyentuh repository.
class AskAi {
  const AskAi(this._repository);

  static const int maxQuestionLength = 400;

  final AiChatRepository _repository;

  Future<({String? answer, bool isFallback, Failure? failure})> call({
    required String question,
  }) async {
    final trimmed = question.trim();

    if (trimmed.isEmpty) {
      return (
        answer: null,
        isFallback: false,
        failure: const ValidationFailure('Pertanyaan tidak boleh kosong.'),
      );
    }

    if (trimmed.length > maxQuestionLength) {
      return (
        answer: null,
        isFallback: false,
        failure: ValidationFailure(
          'Pertanyaan terlalu panjang (maks $maxQuestionLength karakter).',
        ),
      );
    }

    return _repository.ask(question: trimmed);
  }
}
