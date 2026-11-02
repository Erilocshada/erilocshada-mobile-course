import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/presentation/pages/notes_page.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/note_providers.dart';

import 'fake_note_repository.dart';

/// Test widget dari draf AI, ditempel apa adanya.
void main() {
  Future<void> pump(WidgetTester tester, FakeNoteRepository repo) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('kolom pencarian menyaring daftar judul', (tester) async {
    await pump(
      tester,
      FakeNoteRepository(
        notes: [
          Note(
            id: 1,
            title: 'Belanja mingguan',
            updatedAt: DateTime(2026, 10, 1),
          ),
          Note(id: 2, title: 'Rapat kerja', updatedAt: DateTime(2026, 10, 2)),
        ],
      ),
    );

    expect(find.text('Belanja mingguan'), findsOneWidget);
    expect(find.text('Rapat kerja'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('noteSearchField')), 'bel');
    await tester.pump();

    expect(find.text('Belanja mingguan'), findsOneWidget);
    expect(find.text('Rapat kerja'), findsNothing);
  });

  testWidgets('tidak ada hasil menampilkan empty state pencarian', (
    tester,
  ) async {
    await pump(
      tester,
      FakeNoteRepository(
        notes: [
          Note(
            id: 1,
            title: 'Belanja mingguan',
            updatedAt: DateTime(2026, 10, 1),
          ),
        ],
      ),
    );

    await tester.enterText(find.byKey(const Key('noteSearchField')), 'liburan');
    await tester.pump();

    expect(find.textContaining('Tidak ada catatan yang cocok'), findsOneWidget);
    expect(find.text('Belanja mingguan'), findsNothing);
  });
}
