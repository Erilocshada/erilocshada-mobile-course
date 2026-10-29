import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/note_providers.dart';

import 'fake_note_repository.dart';

void main() {
  ProviderContainer containerWith(FakeNoteRepository repository) {
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('notesProvider', () {
    test('sukses dengan repository palsu', () async {
      final container = containerWith(
        FakeNoteRepository(
          notes: [Note(title: 'Tes', updatedAt: DateTime(2026, 10, 1))],
        ),
      );

      final notes = await container.read(notesProvider.future);

      expect(notes, hasLength(1));
      expect(notes.first.title, 'Tes');
    });

    test('kegagalan sumber data menjadi AsyncValue.error', () async {
      final container = containerWith(FakeNoteRepository(failOnFetch: true));

      // Dengarkan provider supaya state tidak ter-dispose saat masih loading.
      final sub = container.listen(notesProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(notesProvider);

      expect(state.hasError, isTrue);
      expect(state.error, isA<Exception>());
      sub.close();
    });

    test('addNote menandai catatan baru belum tersinkron', () async {
      final repository = FakeNoteRepository();
      final container = containerWith(repository);

      await container.read(notesProvider.notifier).addNote(title: 'Baru');

      expect(repository.notes.single.title, 'Baru');
      expect(repository.notes.single.dirty, isTrue);
    });
  });
}
