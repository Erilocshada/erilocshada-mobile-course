import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai_key_store.dart';
import '../../data/gemini_api.dart';
import '../../data/repositories/ai_chat_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../domain/usecases/ask_ai.dart';

/// ==========================================================================
/// Wiring DI fitur ai_chat — satu-satunya tempat layer-layer disatukan.
/// Arah panah: data -> domain <- presentation (dependency rule minggu 7).
/// ==========================================================================

final aiKeyStoreProvider = Provider<AiKeyStore>((ref) => AiKeyStore());

final geminiApiProvider = Provider<GeminiApi>((ref) => GeminiApi());

final aiChatRepositoryProvider = Provider<AiChatRepository>(
  (ref) => AiChatRepositoryImpl(
    keyStore: ref.watch(aiKeyStoreProvider),
    api: ref.watch(geminiApiProvider),
  ),
);

final askAiProvider = Provider<AskAi>(
  (ref) => AskAi(ref.watch(aiChatRepositoryProvider)),
);

final aiChatProvider = NotifierProvider<AiChatNotifier, AiChatState>(
  AiChatNotifier.new,
);

class AiChatState {
  const AiChatState({
    this.messages = const [],
    this.isSending = false,
    this.apiKeyConfigured = false,
  });

  final List<ChatMessage> messages;
  final bool isSending;
  final bool apiKeyConfigured;

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    bool? apiKeyConfigured,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      apiKeyConfigured: apiKeyConfigured ?? this.apiKeyConfigured,
    );
  }
}

class AiChatNotifier extends Notifier<AiChatState> {
  late final AskAi _askAi;
  late final AiKeyStore _keyStore;

  @override
  AiChatState build() {
    _askAi = ref.read(askAiProvider);
    _keyStore = ref.read(aiKeyStoreProvider);

    _refreshKeyStatus();

    return const AiChatState(
      messages: [
        ChatMessage(
          role: ChatRole.assistant,
          text:
              'Halo! Saya asisten Campus Notify. Tanyakan soal jadwal, '
              'pengumuman, atau notifikasi kampus.',
        ),
      ],
    );
  }

  Future<void> _refreshKeyStatus() async {
    final key = await _keyStore.getKey();
    state = state.copyWith(apiKeyConfigured: key != null);
  }

  Future<void> send(String question) async {
    if (state.isSending) return;

    state = state.copyWith(
      isSending: true,
      messages: [
        ...state.messages,
        ChatMessage(role: ChatRole.user, text: question),
      ],
    );

    final result = await _askAi(question: question);

    final reply = ChatMessage(
      role: ChatRole.assistant,
      text: result.answer ?? result.failure?.message ?? 'Terjadi kesalahan.',
      isFallback: result.isFallback,
    );

    state = state.copyWith(isSending: false, messages: [...state.messages, reply]);
  }

  Future<void> saveApiKey(String key) async {
    await _keyStore.saveKey(key);
    state = state.copyWith(apiKeyConfigured: key.trim().isNotEmpty);
  }

  Future<void> clearApiKey() async {
    await _keyStore.clear();
    state = state.copyWith(apiKeyConfigured: false);
  }
}
