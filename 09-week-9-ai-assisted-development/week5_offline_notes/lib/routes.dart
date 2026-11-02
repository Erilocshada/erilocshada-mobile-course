/// Konstanta rute aplikasi (pure Dart — boleh diimpor lintas layer).
///
/// Memakai konvensi yang sama dengan minggu 7/8: halaman mengenal nama rute,
/// bukan menempel string literal di tiap `context.push`.
class RoutePaths {
  static const String home = '/';
  static const String settings = '/settings';
  static const String noteDetail = '/note/:id';

  /// `0` berarti belum ada baris di SQLite: halaman detail membuka mode tambah.
  static const String newNoteId = '0';

  static String note(int id) => '/note/$id';
}
