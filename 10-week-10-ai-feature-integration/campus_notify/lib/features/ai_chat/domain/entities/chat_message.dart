/// Peran dalam percakapan chat AI.
enum ChatRole { user, assistant }

/// Entity domain murni — tanpa import Flutter/API.
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.isFallback = false,
  });

  final ChatRole role;
  final String text;

  /// True bila jawaban berasal dari data lokal (AI tidak tersedia),
  /// bukan dari LLM — dipakai UI untuk menampilkan badge "Mode offline".
  final bool isFallback;
}
