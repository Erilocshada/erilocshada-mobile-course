# Verifikasi grep — sterilitas arsitektur (jobsheet #9)

Perintah dijalankan dari `09-week-9-ai-assisted-development/week5_offline_notes`
di Git Bash (Windows). Output ditempel literal, termasuk exit code:
`grep` mengembalikan **1** ketika tidak ada baris yang cocok — dan untuk
pemeriksaan "harus nol", exit 1 justru hasilnya yang diharapkan.

---

## G1 — `domain/` tidak mengimpor Flutter / SQLite / Dio / SharedPreferences

```
$ grep -rEn "import 'package:(flutter|sqflite|dio|shared_preferences)" lib/features/*/domain
exit=1        # nol hasil -> domain murni Dart
```

Ini pemeriksaan `dependency rule` minggu 7. Kalau ada satu saja import ini,
berarti logika bisnis bersandar ke framework dan tidak bisa diuji tanpa device.

**Catatan cakupan:** `lib/core/db.dart` sengaja **tidak** dimasukkan ke
pemeriksaan ini. Ia infrastruktur bersama (koneksi SQLite dipakai dua fitur),
bukan domain. Memasukkannya akan membuat grep gagal tanpa membuktikan apa pun.

## G2 — UI tidak menyentuh DB / JSON / HTTP / prefs

```
$ grep -rEn "openDatabase|getDatabasesPath|jsonDecode|jsonEncode|Dio\(|SharedPreferences.getInstance|sqflite" \
    lib/features/*/presentation/pages lib/features/*/presentation/widgets
exit=1        # nol hasil -> tidak ada panggilan database dari widget
```

Cakupan sengaja `pages` + `widgets`, **bukan** seluruh `presentation/`. Alasannya:
`presentation/providers/` adalah composition root — tempat layer disatukan, dan
di situlah `Dio(BaseOptions(...))` memang dibangun (meniru
`announcement_providers.dart` minggu 7/8). Kalau seluruh `presentation/`
digrep, perintah ini menemukan `posts_providers.dart:15` dan memberi hasil
positif palsu. Saya laporkan itu sebagai keterbatasan grep, bukan sebagai
"arsitektur bersih".

## G3 — `domain/` tidak mengimpor data layer

```
$ grep -rEn "^import .*data/" lib/features/*/domain
exit=1        # nol hasil
```

Versi pertama grep ini saya tulis `grep -rn "data/" lib/features/*/domain` dan
**kena tiga false positive** dari kalimat komentar (`"pindah ke data/models/..."`).
`^import` mempersempit ke baris import sungguhan. Ini contoh bagus soal mengapa
grep harus dibaca hasilnya, bukan hanya dilihat nol/non-nol.

## G4 — filter pencarian benar-benar berada di domain murni

```
$ grep -rEn "toLowerCase|contains" lib/features/notes/domain/usecases/search_notes.dart
10:    final q = query.trim().toLowerCase();
12:    return notes.where((n) => n.title.toLowerCase().contains(q)).toList();
```

Kecocokan dilakukan di `domain/usecases/`, bukan di widget dan bukan di SQL.
Dipasang oleh AI, saya terima tanpa perubahan.

## G5 — tidak ada `LIKE` di seluruh `lib/`

```
$ grep -rn "LIKE" lib
exit=1        # nol hasil
```

Pemeriksaan ini yang membedakan pekerjaan ini dari sekadar menyalin contoh
jobsheet. Jobsheet §3 membahas `LIKE`; AI **tidak** mengusulkan `LIKE` (ia
memilih filter in-memory), jadi tidak ada yang perlu dibersihkan. Kalau suatu
saat push-down SQL masuk, grep ini penjaga gerbangnya.

## G6 — satu-satunya `rawQuery` adalah penghitung, bukan pencarian

```
$ grep -rn -A2 "rawQuery" lib
lib/features/notes/data/repositories/note_repository_impl.dart:108:      final rows = await db.rawQuery(
lib/features/notes/data/repositories/note_repository_impl.dart-109-        'SELECT COUNT(*) AS c FROM $_table WHERE dirty = 1',
lib/features/notes/data/repositories/note_repository_impl.dart-110-      );
```

`countDirty()` untuk kebutuhan sinkronisasi, tetap di data layer, dan memakai
predikat konstan tanpa penyisipan nilai pengguna. Tidak ada string interpolation
berbasis input user di SQL mana pun.

## G7 — koneksi database tunggal

```
$ grep -rn "openNotesDb\|sharedNotesDb" lib
lib/core/db.dart:11:Future<Database> openNotesDb() async {
lib/core/db.dart:42:Future<Database> sharedNotesDb() => _shared ??= openNotesDb();
lib/features/notes/data/repositories/note_repository_impl.dart:16:    : _openDb = openDb ?? sharedNotesDb;
lib/features/posts/data/repositories/post_cache_repository_impl.dart:18:    : _openDb = openDb ?? sharedNotesDb;
```

Yang hilang sama pentingnya: `sync.dart` minggu 5 memanggil `openNotesDb()` dari
top-level dua kali (baris 36 dan 58), sehingga tiap baca/tulis cache membuka
koneksi baru. File itu sudah tidak ada — grep di atas tidak lagi menemukan
pemanggilan di luar dua repository impl.
