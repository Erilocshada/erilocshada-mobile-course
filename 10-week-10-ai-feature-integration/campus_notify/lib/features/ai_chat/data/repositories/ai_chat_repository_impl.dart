import '../../../../core/failures.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../ai_key_store.dart';
import '../gemini_api.dart';
import '../local_fallback.dart';

/// Implementasi kontrak AI chat:
/// 1. API key dari secure storage — jika belum ada, langsung fallback lokal.
/// 2. Panggil Gemini API; setiap error/timeout/empty response diubah menjadi
///    fallback ramah (bukan exception mentah) sesuai pola Failure minggu 7.
class AiChatRepositoryImpl implements AiChatRepository {
  const AiChatRepositoryImpl({
    required this.keyStore,
    required this.api,
    this.localFallback = const LocalFallback(),
  });

  final AiKeyStore keyStore;
  final GeminiApi api;
  final LocalFallback localFallback;

  @override
  Future<({String? answer, bool isFallback, Failure? failure})> ask({
    required String question,
  }) async {
    final apiKey = await keyStore.getKey();

    if (apiKey == null) {
      return (
        answer: localFallback.answerFor(question),
        isFallback: true,
        failure: const ValidationFailure(
          'API key AI belum diatur — menjawab dengan data lokal.',
        ),
      );
    }

    final result = await api.generate(apiKey: apiKey, question: question);

    if (result.ok && result.text != null) {
      return (answer: result.text, isFallback: false, failure: null);
    }

    // Error API tidak boleh menghentikan aplikasi: fallback ke data lokal.
    return (
      answer: localFallback.answerFor(question),
      isFallback: true,
      failure: NetworkFailure(
        result.reason ?? 'Layanan AI tidak dapat dihubungi.',
      ),
    );
  }
}
