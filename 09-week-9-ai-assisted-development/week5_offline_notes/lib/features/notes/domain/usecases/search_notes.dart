import '../entities/note.dart';

/// Use case murni: menyaring [notes] berdasarkan kecocokan judul
/// (case-insensitive). Bekerja pada daftar yang sudah dimuat sehingga kontrak
/// [NoteRepository] tidak berubah dan SQLite tidak ikut terseret.
class SearchNotes {
  const SearchNotes();

  List<Note> call(List<Note> notes, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return notes;
    return notes.where((n) => n.title.toLowerCase().contains(q)).toList();
  }
}
