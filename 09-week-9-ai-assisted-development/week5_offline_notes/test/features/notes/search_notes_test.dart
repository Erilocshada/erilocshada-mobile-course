import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/usecases/search_notes.dart';

/// Test ini berasal dari draf AI, ditempel apa adanya.
void main() {
  const search = SearchNotes();
  final notes = [
    Note(id: 1, title: 'Belanja mingguan', updatedAt: DateTime(2026, 10, 1)),
    Note(id: 2, title: 'Rapat kerja', updatedAt: DateTime(2026, 10, 2)),
    Note(id: 3, title: 'belajar flutter', updatedAt: DateTime(2026, 10, 3)),
  ];

  group('SearchNotes', () {
    test('query kosong mengembalikan seluruh catatan', () {
      expect(search(notes, ''), hasLength(3));
      expect(search(notes, '   '), hasLength(3));
    });

    test('pencocokan judul tidak peka huruf besar/kecil', () {
      expect(search(notes, 'BELANJA').map((n) => n.id), [1]);
      expect(search(notes, 'bel').map((n) => n.id).toSet(), {1, 3});
    });

    test('tidak ada yang cocok menghasilkan daftar kosong', () {
      expect(search(notes, 'liburan'), isEmpty);
    });

    // Tambahan saya, bukan dari AI: jobsheet menyebut "search JUDUL notes",
    // jadi body sengaja tidak ikut dicari. Ditest supaya keputusan ini terbaca
    // sebagai pilihan, bukan kelalaian.
    test('isi catatan (body) sengaja tidak dicari', () {
      final withBody = [
        Note(
          id: 9,
          title: 'Jadwal',
          body: 'liburan ke pantai',
          updatedAt: DateTime(2026, 10, 4),
        ),
      ];

      expect(search(withBody, 'liburan'), isEmpty);
      expect(search(withBody, 'jadwal'), hasLength(1));
    });

    // Tambahan saya: pembuktian alasan menolak push-down `LIKE` ke SQLite.
    // LIKE pada SQLite hanya case-insensitive untuk ASCII, sedangkan
    // String.toLowerCase() di Dart menangani karakter beraksen.
    test('judul beraksen non-ASCII tetap cocok lintas huruf besar/kecil', () {
      final accented = [
        Note(
          id: 10,
          title: 'Résumé dosen',
          body: '',
          updatedAt: DateTime(2026, 10, 5),
        ),
      ];

      expect(search(accented, 'résumé'), hasLength(1));
      expect(search(accented, 'RÉSUMÉ'), hasLength(1));
    });

    // BATES yang diketahui, bukan tujuan desain. Test ini dikunci sebagai
    // dokumentasi setelah AI Verification Challenge (docs/AI_CHALLENGE.md
    // temuan #3): toLowerCase() melakukan case folding, TIDAK menormalkan
    // Unicode. Memperbaikinya butuh normalisasi NFC/NFD, dan slot Batas pada
    // prompt minggu 9 melarang menambah dependensi.
    test('bates: judul NFD tidak cocok dengan query NFC', () {
      const nfdTitle = 'Re\u0301sume\u0301 dosen'; // e + combining acute
      const nfcQuery = 'r\u00e9sum\u00e9'; // é precomposed, U+00E9
      expect(nfdTitle.length, greaterThan(nfcQuery.length));

      final nfd = [
        Note(id: 11, title: nfdTitle, updatedAt: DateTime(2026, 10, 6)),
      ];
      expect(search(nfd, nfcQuery), isEmpty);
    });
  });
}
