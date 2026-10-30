import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/delete_note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/search_notes.dart';
import '../../domain/usecases/sync_notes.dart';
import '../../domain/usecases/update_note.dart';

/// Wiring DI fitur notes — satu-satunya tempat layer-layer disatukan
/// (pola yang sama dengan `announcement_providers.dart` minggu 7/8).

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepositoryImpl(),
);

final getNotesProvider = Provider<GetNotes>(
  (ref) => GetNotes(ref.watch(noteRepositoryProvider)),
);

final addNoteProvider = Provider<AddNote>(
  (ref) => AddNote(ref.watch(noteRepositoryProvider)),
);

final updateNoteProvider = Provider<UpdateNote>(
  (ref) => UpdateNote(ref.watch(noteRepositoryProvider)),
);

final deleteNoteProvider = Provider<DeleteNote>(
  (ref) => DeleteNote(ref.watch(noteRepositoryProvider)),
);

final syncNotesProvider = Provider<SyncNotes>(
  (ref) => SyncNotes(ref.watch(noteRepositoryProvider)),
);

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() {
    // watch di build agar daftar dimuat ulang bila dependensi berubah;
    // pemanggilan setelah build memakai read.
    ref.watch(getNotesProvider);
    return _fetch();
  }

  Future<List<Note>> _fetch() async {
    final result = await ref.read(getNotesProvider).call();
    if (result.failure != null) throw Exception(result.failure!.message);
    return result.notes ?? const [];
  }

  /// Setiap mutasi: loading -> jalankan aksi -> muat ulang daftar.
  /// Pola `AsyncValue.guard` dipertahankan dari minggu 5 karena test error
  /// lama bergantung pada `state.hasError`.
  Future<void> _mutate(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await action();
      return _fetch();
    });
  }

  Future<void> addNote({required String title, String body = ''}) =>
      _mutate(() async {
        final result = await ref
            .read(addNoteProvider)
            .call(title: title, body: body);
        if (result.failure != null) throw Exception(result.failure!.message);
      });

  Future<void> updateNote({
    required int id,
    required String title,
    String body = '',
  }) => _mutate(() async {
    final result = await ref
        .read(updateNoteProvider)
        .call(id: id, title: title, body: body);
    if (result.failure != null) throw Exception(result.failure!.message);
  });

  Future<void> deleteNote(int id) => _mutate(() async {
    final result = await ref.read(deleteNoteProvider).call(id);
    if (result.failure != null) throw Exception(result.failure!.message);
  });

  Future<void> sync() => _mutate(() async {
    final result = await ref.read(syncNotesProvider).call();
    if (result.failure != null) throw Exception(result.failure!.message);
  });
}

/// Judul aktif yang sedang diketik pengguna di halaman daftar catatan.
///
/// AI mengusulkan `StateProvider<String>`. Ditolak: di Riverpod 3 kelas itu
/// hanya terekspos dari `package:flutter_riverpod/legacy.dart`, bukan dari
/// import utama yang dipakai proyek ini. `NotifierProvider` adalah padanan
/// non-legacy dan tetap murni state UI.
class NoteSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

final noteSearchQueryProvider = NotifierProvider<NoteSearchQuery, String>(
  NoteSearchQuery.new,
);

/// Daftar catatan terfilter judul — turunan [notesProvider] + query.
/// Penyaringan bersifat sinkron lewat [whenData], tanpa menambah jalur mutasi
/// baru pada NotesNotifier.
///
/// Usulan AI `searchNotesProvider = Provider<SearchNotes>(...)` saya tolak:
/// [SearchNotes] murni dan tanpa dependensi, jadi tidak ada apa pun yang bisa
/// di-inject. Objek dibuat langsung di tempat pemakaiannya.
final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final query = ref.watch(noteSearchQueryProvider);
  return ref
      .watch(notesProvider)
      .whenData((notes) => const SearchNotes()(notes, query));
});
