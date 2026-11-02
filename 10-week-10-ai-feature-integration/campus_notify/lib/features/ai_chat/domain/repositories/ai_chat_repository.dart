import '../../../../core/failures.dart';

/// Kontrak domain fitur AI chat.
/// Implementasinya (Gemini API + fallback lokal) hidup di data layer,
/// sehingga use case, notifier, dan UI bisa diuji tanpa plugin/Jaringan.
abstract class AiChatRepository {
  Future<({String? answer, bool isFallback, Failure? failure})> ask({
    required String question,
  });
}
