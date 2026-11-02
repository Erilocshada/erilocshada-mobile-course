import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/ai_chat/data/ai_key_store.dart';
import 'package:campus_notify/features/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'package:campus_notify/features/ai_chat/presentation/pages/chat_page.dart';
import 'package:campus_notify/features/ai_chat/presentation/providers/ai_chat_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeKeyStore extends AiKeyStore {
  @override
  Future<String?> getKey() async => null; // mode offline

  @override
  Future<void> saveKey(String key) async {}

  @override
  Future<void> clear() async {}
}

class _FakeRepo implements AiChatRepository {
  @override
  Future<({String? answer, bool isFallback, Failure? failure})> ask({
    required String question,
  }) async {
    return (
      answer: 'Jawaban lokal untuk: $question',
      isFallback: true,
      failure: const ValidationFailure('mode offline'),
    );
  }
}

void main() {
  Widget harness() => ProviderScope(
    overrides: [
      aiKeyStoreProvider.overrideWithValue(_FakeKeyStore()),
      aiChatRepositoryProvider.overrideWithValue(_FakeRepo()),
    ],
    child: const MaterialApp(home: ChatPage()),
  );

  testWidgets('halaman chat mengirim pesan dan menampilkan fallback badge',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Asisten AI Kampus'), findsOneWidget);
    expect(find.textContaining('API key AI belum diatur'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'kapan UTS?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('kapan UTS?'), findsOneWidget);
    expect(find.text('Jawaban lokal untuk: kapan UTS?'), findsOneWidget);
    expect(find.text('Mode offline'), findsOneWidget);
  });

  testWidgets('pesan kosong tidak dikirim', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // Hanya greeting yang ada — tidak ada bubble user, tidak ada reply.
    expect(find.textContaining('Halo!'), findsOneWidget);
    expect(find.text('Mode offline'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
