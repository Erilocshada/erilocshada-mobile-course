import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/presentation/pages/note_detail_page.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/note_providers.dart';

import 'fake_note_repository.dart';

/// Test regresi bug minggu 5: NoteDetailPage mode edit memanggil addNote,
/// sehingga Simpan menghasilkan catatan duplikat alih-alih memperbarui.
void main() {
  testWidgets(
    'menyimpan hasil edit memperbarui catatan, tidak menambah baris baru',
    (tester) async {
      final repository = FakeNoteRepository(
        notes: [
          Note(
            id: 1,
            title: 'Belanja mingguan',
            body: 'susu dan roti',
            updatedAt: DateTime(2026, 10, 1),
          ),
        ],
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const _WarmupPage()),
          GoRoute(
            path: '/note/:id',
            builder: (context, state) =>
                NoteDetailPage(noteId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [noteRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.push('/note/1');
      await tester.pumpAndSettle();

      expect(
        find.text('Belanja mingguan'),
        findsOneWidget,
        reason: 'halaman edit harus menampilkan isi catatan yang ada',
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'Belanja bulanan',
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(
        repository.notes,
        hasLength(1),
        reason:
            'mode edit wajib memperbarui catatan id=1, bukan membuat duplikat',
      );
      expect(repository.notes.single.id, 1);
      expect(repository.notes.single.title, 'Belanja bulanan');
    },
  );
}

/// Halaman penghangat yang menunggu daftar catatan termuat, meniru kondisi
/// nyata: NoteDetailPage selalu dibuka dari NotesPage yang sudah mengisi
/// notesProvider.
class _WarmupPage extends ConsumerWidget {
  const _WarmupPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notesProvider);
    return const Scaffold(body: SizedBox.shrink());
  }
}
