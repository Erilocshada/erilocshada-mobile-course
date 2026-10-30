# Prompt mentah #1 — fitur pencarian judul catatan

Ditulis **sebelum** ada satu baris kode fitur ini, dan dikirim apa adanya ke AI.
Sengaja tidak menyebut mekanisme pencarian (SQL/`LIKE`/filter in-memory) dan tidak
menyebut layer tujuan, supaya hasil yang keluar benar-benar keputusan AI, bukan
hasil yang saya arahkan. Format lima slot sesuai jobsheet #9 §"Formula 5 slot".

```
Peran: senior Flutter developer.

Konteks: proyek Flutter "week5_offline_notes". Dependensi: flutter_riverpod ^3.4.3,
sqflite ^2.4.4, go_router ^14.8.0, path ^1.9.1. Struktur feature-first:
lib/core/{db.dart, failures.dart} dan lib/features/<fitur>/{domain, data, presentation}.
Fitur notes sudah punya:
  domain/entities/note.dart            -> class Note { int? id; String title; String body; DateTime updatedAt; bool dirty; }
  domain/repositories/note_repository.dart  -> abstract class NoteRepository
  domain/usecases/{get_notes, add_note, update_note, delete_note, sync_notes}.dart
  data/models/note_model.dart          -> NoteModel extends Note, toMap/fromMap baris SQLite
  data/repositories/note_repository_impl.dart -> NoteRepositoryImpl (sqflite)
  presentation/providers/note_providers.dart   -> noteRepositoryProvider, notesProvider (AsyncNotifierProvider<NotesNotifier, List<Note>>)
  presentation/pages/notes_page.dart   -> ConsumerWidget, ref.watch(notesProvider).when(...), ListView.builder, NoteTile
Tabel SQLite: notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
body TEXT NOT NULL DEFAULT '', updated_at TEXT NOT NULL, dirty INTEGER NOT NULL DEFAULT 0).

Tugas: tambahkan fitur pencarian judul catatan pada halaman daftar catatan,
lengkap dengan empty state ketika tidak ada hasil.

Batas: jangan mengubah arsitektur yang sudah ada, jangan menambah dependensi baru,
jangan menyentuh file di luar fitur notes, maksimal 80 baris kode baru.

Output: kode lengkap, 3 test case, dan cara menjalankan test-nya.
```

Konteks yang sengaja **tidak** ditempelkan ke AI: token/secret (proyek ini memang tidak
punya — minggu 5 belum memakai Firebase, tidak ada `google-services.json`), dan tidak
seluruh repo ditempel, hanya kontrak domain + struktur folder + versi package, sesuai
jobsheet #9 §"Beri konteks, bukan secret".
