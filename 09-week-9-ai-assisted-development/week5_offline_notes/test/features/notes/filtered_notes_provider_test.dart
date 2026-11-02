import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/note_providers.dart';

import 'fake_note_repository.dart';

/// Test dari draf AI. Satu-satunya baris yang saya ubah: `.state = ...`
/// menjadi `.setQuery(...)`, karena `StateProvider` AI ditolak (lihat
/// docs/ai-log.md temuan #1).
void main() {
  test('filteredNotesProvider mengikuti noteSearchQueryProvider', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(
            notes: [
              Note(id: 1, title: 'Belanja', updatedAt: DateTime(2026, 10, 1)),
              Note(id: 2, title: 'Kerja', updatedAt: DateTime(2026, 10, 2)),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(notesProvider.future);
    expect(container.read(filteredNotesProvider).value, hasLength(2));

    container.read(noteSearchQueryProvider.notifier).setQuery('ker');
    expect(container.read(filteredNotesProvider).value!.map((n) => n.id), [2]);

    container.read(noteSearchQueryProvider.notifier).setQuery('');
    expect(container.read(filteredNotesProvider).value, hasLength(2));
  });
}
