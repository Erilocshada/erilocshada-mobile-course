import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/presentation/pages/notes_page.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/note_providers.dart';

import 'fake_note_repository.dart';

/// Test ini lahir dari AI Verification Challenge (docs/AI_CHALLENGE.md),
/// bukan dari draf awal. Tiap test ditulis lebih dulu untuk membuktikan
/// klaim reviewer, baru kodenumnya diputuskan.
void main() {
  List<Note> sampleNotes() => [
    Note(id: 1, title: 'Belanja mingguan', updatedAt: DateTime(2026, 10, 1)),
    Note(id: 2, title: 'Rapat kerja', updatedAt: DateTime(2026, 10, 2)),
  ];

  Future<void> pumpPage(
    WidgetTester tester,
    FakeNoteRepository repo,
    String pageKey,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(home: NotesPage(key: ValueKey(pageKey))),
      ),
    );
    await tester.pumpAndSettle();
  }

  TextField searchField(WidgetTester tester) =>
      tester.widget<TextField>(find.byKey(const Key('noteSearchField')));

  testWidgets(
    'temuan #2 reviewer: query tetap tampil di kolom setelah halaman di-remount',
    (tester) async {
      await pumpPage(tester, FakeNoteRepository(notes: sampleNotes()), 'a');

      await tester.enterText(find.byKey(const Key('noteSearchField')), 'ker');
      await tester.pump();

      expect(find.text('Rapat kerja'), findsOneWidget);
      expect(find.text('Belanja mingguan'), findsNothing);

      // Ganti key: State NoteSearchField dibuang, provider query tetap hidup
      // karena scope-nya aplikasi. Ini yang terjadi saat kembali dari halaman
      // detail catatan.
      await pumpPage(tester, FakeNoteRepository(notes: sampleNotes()), 'b');

      expect(
        searchField(tester).controller!.text,
        'ker',
        reason:
            'kolom kosong di atas daftar yang masih terfilter = dua sumber '
            'kebenaran yang tidak disinkronkan',
      );
    },
  );

  testWidgets('temuan #3 reviewer: tombol clear mengembalikan seluruh daftar', (
    tester,
  ) async {
    await pumpPage(tester, FakeNoteRepository(notes: sampleNotes()), 'a');

    await tester.enterText(find.byKey(const Key('noteSearchField')), 'ker');
    await tester.pump();
    expect(find.text('Belanja mingguan'), findsNothing);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(searchField(tester).controller!.text, isEmpty);
    expect(find.text('Belanja mingguan'), findsOneWidget);
    expect(find.text('Rapat kerja'), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsNothing);
  });

  testWidgets(
    'temuan #1 reviewer: cabang error tidak menelan query secara diam-diam',
    (tester) async {
      await pumpPage(tester, FakeNoteRepository(failOnFetch: true), 'a');
      await tester.pumpAndSettle();

      expect(find.textContaining('Gagal memuat catatan'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('noteSearchField')), 'ker');
      await tester.pump();

      // Perilaku yang diikat: error tetap yang ditampilkan, query tidak
      // mengubah halaman menjadi "tidak ada hasil" yang menipu.
      expect(find.textContaining('Gagal memuat catatan'), findsOneWidget);
      expect(find.textContaining('Tidak ada catatan yang cocok'), findsNothing);
    },
  );

  testWidgets('temuan #3 reviewer: query tetap terpakai melewati _mutate', (
    tester,
  ) async {
    final repo = FakeNoteRepository(notes: sampleNotes());
    await pumpPage(tester, repo, 'a');

    await tester.enterText(find.byKey(const Key('noteSearchField')), 'kerja');
    await tester.pump();
    expect(find.text('Belanja mingguan'), findsNothing);

    // NotesNotifier._mutate mengeset state = loading lalu memuat ulang daftar.
    // Provider query harus bertahan melewati kilat spinner itu.
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('noteSearchField'))),
    );
    await container.read(notesProvider.notifier).addNote(title: 'Kerja bakti');
    await tester.pumpAndSettle();

    expect(find.text('Kerja bakti'), findsOneWidget);
    expect(find.text('Rapat kerja'), findsOneWidget);
    expect(find.text('Belanja mingguan'), findsNothing);
    expect(searchField(tester).controller!.text, 'kerja');
  });
}
