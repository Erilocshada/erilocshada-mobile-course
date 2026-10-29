import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/pages/note_detail_page.dart';

/// Repository in-memory yang mencatat setiap tulisan, supaya efek tombol
/// Simpan pada mode edit bisa dilihat langsung.
class RecordingNoteRepository extends NoteRepository {
  RecordingNoteRepository(this.notes)
    : super(openDb: () => throw UnimplementedError());

  final List<Note> notes;
  int _nextId = 100;

  @override
  Future<List<Note>> fetchNotes() async => List.of(notes);

  @override
  Future<Note> addNote({required String title, String body = ''}) async {
    final note = Note(
      id: _nextId++,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    notes.add(note);
    return note;
  }

  @override
  Future<void> deleteNote(int id) async => notes.removeWhere((n) => n.id == id);

  @override
  Future<void> updateNote({
    required int id,
    required String title,
    String body = '',
  }) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index == -1) return;
    notes[index] = Note(
      id: id,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
  }
}

/// Halaman penghangat yang benar-benar menunggu daftar catatan termuat,
/// meniru kondisi nyata: NoteDetailPage selalu dibuka dari NotesPage
/// yang sudah mengisi notesProvider.
class _WarmupPage extends ConsumerWidget {
  const _WarmupPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notesProvider);
    return const Scaffold(body: SizedBox.shrink());
  }
}

void main() {
  testWidgets(
    'menyimpan hasil edit memperbarui catatan, tidak menambah baris baru',
    (tester) async {
      final repository = RecordingNoteRepository([
        Note(
          id: 1,
          title: 'Belanja mingguan',
          body: 'susu dan roti',
          updatedAt: DateTime(2026, 10, 1),
        ),
      ]);
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
        repository.notes.length,
        1,
        reason:
            'mode edit wajib memperbarui catatan id=1, bukan membuat duplikat',
      );
      expect(repository.notes.single.id, 1);
      expect(repository.notes.single.title, 'Belanja bulanan');
    },
  );
}
