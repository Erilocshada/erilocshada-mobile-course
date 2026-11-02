import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/notes/data/models/note_model.dart';

/// Test serialisasi pernah tinggal di `test/note_test.dart` bersama test
/// provider, karena saat itu `Note` sendiri yang memegang `toMap`/`fromMap`.
/// Setelah bentuk baris SQLite dipindah ke `NoteModel`, test ini ikut ke data
/// layer dan entity domain tidak punya test serialisasi sama sekali — itu
/// memang tujuannya.
void main() {
  group('NoteModel', () {
    test('fromMap aman terhadap field yang hilang', () {
      final note = NoteModel.fromMap({'title': 'Belanja'});

      expect(note.title, 'Belanja');
      expect(note.body, '');
      expect(note.dirty, isFalse);
    });

    test('flag dirty bertahan pada serialisasi', () {
      final note = NoteModel(
        title: 'a',
        updatedAt: DateTime(2026, 9, 18),
        dirty: true,
      );

      expect(NoteModel.fromMap(note.toMap()).dirty, isTrue);
    });

    test('updated_at tidak valid jatuh ke epoch, bukan exception', () {
      final note = NoteModel.fromMap({
        'title': 'x',
        'updated_at': 'bukan-tanggal',
      });

      expect(note.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });
}
