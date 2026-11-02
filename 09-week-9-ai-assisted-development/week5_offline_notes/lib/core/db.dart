import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Infrastruktur bersama: satu file SQLite dipakai dua fitur
/// (tabel `notes` oleh fitur notes, `cached_posts` oleh fitur posts).
///
/// [sharedNotesDb] adalah satu-satunya jalan masuk ke koneksi. Ini menutup
/// celah lama di `sync.dart`, yang memanggil `openNotesDb()` langsung dari
/// top-level sehingga membuka koneksi baru setiap panggilan dan melewati
/// repository.
Future<Database> openNotesDb() async {
  final dir = await getDatabasesPath();
  return openDatabase(
    p.join(dir, 'offline_notes.db'),
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE cached_posts(
          id INTEGER PRIMARY KEY,
          payload TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
    },
  );
}

Future<Database>? _shared;

/// Membuka koneksi sekali dan membagikan instance yang sama ke semua
/// data source. Signature-nya sama dengan `Future<Database> Function()`,
/// jadi bisa di-inject ke repository impl mana pun.
Future<Database> sharedNotesDb() => _shared ??= openNotesDb();
