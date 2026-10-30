# AI Log — Jobsheet #9 AI-Assisted Development / Vibe Coding

Proyek: `week5_offline_notes` (SQLite + Riverpod 3), snapshot minggu 5 yang
lebih dulu saya naikkan ke Clean Architecture standar minggu 7/8.
Alat AI: Qoder CLI (agent terpisah, konteks bersih — tidak diberi tahu hasil
yang saya harapkan). Tanggal: 30 Oktober 2026.

Kebijakan yang saya pegang: **klaim AI adalah hipotesis sampai ada bukti.**
Bukti di sini berarti salah satu dari: keluaran `flutter analyze`, hasil `grep`
ke sumber package, atau test yang gagal/lolos. Bukan "kebanyakan AI bilang
begitu".

---

## 1. Prompt

Lima slot, ditulis **sebelum** ada satu baris kode fitur ini, dan sengaja tidak
menyebut mekanisme pencarian maupun layer tujuan. Teks lengkap:
[`prompt-mentah-search-notes.md`](prompt-mentah-search-notes.md).

| Slot | Isi |
|---|---|
| Peran | senior Flutter developer |
| Konteks | struktur feature-first, daftar file fitur notes, `pubspec` versi package, skema tabel `notes` |
| Tugas | pencarian **judul** catatan di halaman daftar + empty state ketika tidak ada hasil |
| Batas | jangan ubah arsitektur, tanpa dependensi baru, hanya file fitur notes, maks 80 baris baru |
| Output | kode lengkap + 3 test case + cara menjalankan |

Konteks yang ditempel: struktur folder, kontrak repository, versi package —
sesuai anjuran jobsheet. Yang tidak ditempel: secret. Proyek minggu 5 memang
tidak punya Firebase dan tidak ada `google-services.json` (saya cek, bukan
asumsi), jadi tidak ada yang perlu disenyapkan — ini bukan klaim bahwa saya
"membersihkan token".

## 2. Output awal AI

Terekam verbatim di [`ai-output-mentah.md`](ai-output-mentah.md). Ringkasnya:
AI mengembalikan `SearchNotes` sebagai filter murni di domain, satu provider
turunan `filteredNotesProvider`, kolom pencarian `NoteSearchField`, dua empty
state, dan tiga file test.

## 3. Verifikasi 6 langkah

| Langkah | Yang saya lakukan | Hasil |
|---|---|---|
| Baca tiap baris | menandai dua klaim yang bisa diuji | klaim API + klaim jumlah baris |
| Cek import | `flutter analyze` pada draf yang ditempel persis | **4 error** (temuan #1, #2) |
| Cek API nyata | grep ke sumber package di pub cache | `whenData` **benar**, `StateProvider` **salah** |
| `flutter analyze` | setelah koreksi | `No issues found!` |
| Test | 3 test AI + 3 test tambahan saya | **17 hijau** |
| Uji manual | 3 query di device | lihat `screenshots/` |

## 4. Temuan dan bukti

### Temuan #1 — `StateProvider` tidak ada di Riverpod 3 yang dipakai proyek ini. **DITOLAK, terbukti salah.**

AI menulis di awal jawabannya: *"verified the Riverpod 3.4.3 API (...
`StateProvider` is exported via flutter_riverpod)"*.

Bukti A — `flutter analyze` atas kode yang ditempel persis seperti aslinya:

```
error - The function 'StateProvider' isn't defined. Try importing the library
that defines 'StateProvider' ... note_providers.dart:105:33 - undefined_function
```

Bukti B — grep ke sumber package (bukan ke ingatan saya):

```
$ grep -rn "class StateProvider" .../riverpod-3.4.3/lib
.../lib/src/providers/legacy/state_provider.dart:39:final class StateProvider<ValueT>

$ grep -n "StateProvider" .../riverpod-3.4.3/lib/riverpod.dart
(nol hasil)

$ sed -n '1,7p' .../riverpod-3.4.3/lib/legacy.dart
export 'src/internals.dart'
    show StateNotifier, StateController, StateNotifierProvider, StateProvider, ...
```

`StateProvider` berada di folder `legacy/`, beranotasi `@publicInLegacy`, dan
hanya terekspos lewat `package:flutter_riverpod/legacy.dart`. Library utama
`flutter_riverpod.dart` hanya meng-export `change_notifier_provider.dart` dari
legacy. Jadi kalimat "sudah diverifikasi" dari AI adalah klaim verifikasi yang
tidak benar — justru kalimat semacam ini yang paling mahal, karena membuat
pembaca berhenti menguji.

**Keputusan:** tolak. Ganti dengan `NotifierProvider<NoteSearchQuery, String>`
(padanan non-legacy, tetap murni state UI). API `.state = ...` ikut berubah
menjadi `.setQuery(...)` di satu file test.

### Temuan #2 — jalur import relatif salah kedalaman. **DITERIMA + DIPERBAIKI, terbukti.**

AI menulis untuk `presentation/providers/note_providers.dart`:
`import '../domain/usecases/search_notes.dart';`
Dari folder itu, `../domain/` menunjuk ke `presentation/domain/` yang tidak ada.
Yang benar `../../domain/`.

Bukti: `flutter analyze` menghasilkan `uri_does_not_exist` dan dua error turunan
(`SearchNotes isn't a type`, `SearchNotes isn't a class`) — persis pola
"method/path fiktif" di jobsheet §3. Saya tempel baris AI apa adanya saat
verifikasi, tidak diam-diam memperbaikinya, supaya buktinya nyata.

### Temuan #3 — klaim "≈73 baris, di bawah batas 80" tidak benar. **DIBANTAH dengan pengukuran.**

Bukti, `git diff --numstat` atas file produksi:

```
14  lib/features/notes/domain/usecases/search_notes.dart
70  lib/features/notes/presentation/pages/notes_page.dart
32  lib/features/notes/presentation/providers/note_providers.dart
                       -> tambah=116  hapus=8
```

Angka final 116 sudah termasuk koreksi saya (~15 baris untuk kelas
`NoteSearchQuery` menggantikan satu baris `StateProvider`). Draf AI sendiri
sekitar 101 baris — tetap melampaui batas 80 yang disebut di slot **Batas**
prompt-nya sendiri, sambil mengklaim patuh.

Ini kelas halusinasi "yakin tapi salah": bukan API fiktif, tapi klaim tentang
pekerjaannya sendiri. Pelajaran praktis: angka yang AI sebut tanpa perintah
yang menghasilkan angka itu harus diukur, bukan dipercaya.

### Klaim AI yang ternyata BENAR (biarkan penyeimbang tercatat)

*AsyncValue.whenData exists* — benar:
`grep -n whenData .../riverpod-3.4.3/lib/src/core/async_value.dart`
→ `168: AsyncValue<NewT> whenData<NewT>(NewT Function(ValueT value) cb)`.
Keputusan desainnya juga benar: karena data daftar sudah dimuat `notesProvider`,
menyaring ulang tidak perlu menyentuh SQLite sama sekali.

## 5. Tabel usulan AI vs keputusan final

| File | Usulan AI | Keputusan | Alasan teknis | Bukti |
|---|---|---|---|---|
| `domain/usecases/search_notes.dart` | `SearchNotes` murni, `title.toLowerCase().contains(q)`, query kosong → semua | **Terima apa adanya** | Sudah memenuhi rubrik #9(2): filter di use case domain murni, bisa diuji tanpa DB, Unicode-safe | `search_notes_test.dart` 5 test hijau |
| `providers/note_providers.dart` — state query | `StateProvider<String>` | **Tolak** | Legacy-only di Riverpod 3, tidak terekspos dari import utama | analyze `undefined_function` + grep pub cache |
| `providers/note_providers.dart` — `searchNotesProvider` | bungkus `SearchNotes` dengan `Provider` DI | **Tolak** | Kelas tanpa dependensi: tidak ada yang di-inject, hanya menambah satu lapisan tak teruji | dijalankan tanpa provider itu, analyze + 17 test tetap hijau |
| `providers/note_providers.dart` — `filteredNotesProvider` | `Provider<AsyncValue<List<Note>>>` via `whenData` | **Terima** | Memisahkan state filter dari `NotesNotifier`, tanpa jalur mutasi baru | `filtered_notes_provider_test.dart` hijau |
| `providers/note_providers.dart` — baris import | `'../domain/usecases/search_notes.dart'` | **Terima + koreksi** | Kedalaman relatif salah dari `presentation/providers/` | analyze `uri_does_not_exist` |
| `pages/notes_page.dart` — `NoteSearchField` | `ConsumerStatefulWidget` + `TextEditingController` lokal | **Terima** | Controller lokal menjaga kursor saat rebuild; `TextField` (bukan `SearchBar`) memilih tidak menaikkan Flutter SDK | widget test hijau |
| `pages/notes_page.dart` — dua empty state | bedakan "belum ada catatan" vs "tidak ada hasil untuk x" | **Terima** | Tanpa ini, hasil kosong setelah mencari terbaca seperti data hilang | `notes_search_widget_test.dart` hijau |
| `pages/notes_page.dart` — jumlah baris | klaim "di bawah batas 80" | **Ditolak sebagai klaim, kodenya tetap dipakai** | Terukur 116 (±101 untuk draf AI) | `git diff --numstat` |
| `test/search_notes_test.dart` | 3 test | **Terima + tambah 2** | Perlu menegaskan body sengaja dikecualikan, dan pembuktian Unicode | 5 test hijau |

## 6. Debug dengan test merah (dari Tahap A, proyek ini)

Bukan kode AI, tapi bukti alur debug jobsheet §"Debug dengan test merah".

1. **Reproduksi:** buka catatan id=1, ubah judul, tekan Simpan.
2. **Isolasi:** `NoteDetailPage` punya satu jalur tulis (`addNote`) untuk dua
   niat; `isNew` sudah dihitung di baris 50 tapi hanya dipakai untuk judul
   AppBar, tidak pernah untuk memilih operasi.
3. **Test merah:** `Expected: <1>  Actual: <2>` — commit `2c2b623`.
4. **Perbaiki kecil:** tambah `updateNote` (repository → notifier → halaman),
   commit `6ac5d07` → 7 test hijau.
5. **Akar masalah:** bukan SQLite, bukan Riverpod — model halaman tidak memetakan
   "edit" sebagai operasi terpisah dari "tambah". Type-checker tidak menangkap
   ini karena `addNote` memang memvalidasi parameternya; hanya test perilaku
   yang bisa melihatnya.

## 7. Refactor yang saya lakukan sendiri

Jobsheet #9 §"Refactoring Challenge", tiga-tiganya berlaku ke kode hasil AI:

1. **Fungsi kecil.** `NoteTile` dan `SyncBadge` sudah saya pisah dari
   `notes_page.dart` (166 baris → file khusus) sebelum fitur search masuk.
   Tidak ada fungsi baru di atas 40 baris.
2. **Filter ke domain murni.** `SearchNotes` tinggal di `domain/usecases/`;
   UI hanya membaca `filteredNotesProvider`. Tidak ada panggilan database dari
   widget — dibuktikan dengan grep (`docs/GREP_VERIFICATION.md`).
3. **Tidak ada import lintas layer.** `domain/` tidak mengimpor Flutter/sqflite/
   Dio/SharedPreferences; `presentation/pages|widgets` tidak menyentuh
   `openDatabase`/`jsonDecode`/`Dio(`.

## 8. Verifikasi akhir

Angka di bawah adalah keadaan **setelah** ronde kedua (`docs/AI_CHALLENGE.md`) menambah
5 test dan satu perbaikan; sebelum ronde itu gerbangnya hijau dengan 17 test.

```
$ flutter analyze
No issues found! (ran in 4.4s)

$ dart format --output=none --set-exit-if-changed .
Formatted 39 files (0 changed) in 0.10 seconds

$ flutter test
00:04 +22: All tests passed!
```

## 9. Penjelasan tanpa membuka AI

Kalau ditanya di depan kelas tanpa laptop AI, ini yang saya katakan:

- **Kenapa filter di domain, bukan `LIKE` di SQLite?** Karena dataset ini sudah
  dimuat penuh ke memori oleh `notesProvider`, sehingga SQL `LIKE` tidak
  menghemat apa pun tapi membuat logika pencocokan tidak bisa diuji tanpa DB.
  Tambahan: `LIKE` hanya case-insensitive untuk ASCII, sedangkan
  `String.toLowerCase()` menangani karakter beraksen — test `résumé` / `RÉSUMÉ`
  membuktikannya. Kalau nanti daftarnya besar dan perlu di-push-down, keputusan
  ini harus ditinjau ulang; itu batas yang saya sadari.
- **Kenapa query bukan `StateProvider`?** Riverpod 3 menyimpannya di jalur
  legacy; proyek ini mengimpor `flutter_riverpod.dart`, jadi satu-satunya cara
  memakai `StateProvider` adalah menambah dependensi pada API yang disiapkan
  untuk hilang.
- **Kenapa `SearchNotes` tidak dibungkus provider?** Tidak ada yang di-inject.
  Provider untuk kelas tanpa dependensi cuma menambah permukaan yang bisa salah.
- **Kenapa hanya judul?** Jobsheet menyebut "search judul notes". Keputusannya
  saya kunci dengan test supaya tidak berubah diam-diam.
- **Kenapa `TextField`, bukan `SearchBar`?** `SearchBar` butuh Flutter ≥ 3.29;
  batas prompt melarang menaikkan dependensi/SDK.

## 10. Checklist mandiri jobsheet #9

- [x] Prompt 5-slot + konteks tercatat, dan **netral** (tidak mengarahkan solusi)
- [x] Output awal AI disimpan verbatim
- [x] `flutter analyze` bersih, `flutter test` hijau (22 test)
- [x] ≥1 temuan AI dibuktikan benar lalu diperbaiki — temuan #1 dan #2 (ronde generate),
      temuan #2 reviewer (ronde challenge, lihat `docs/AI_CHALLENGE.md`)
- [x] ≥1 usulan AI ditolak dengan alasan teknis tertulis — `StateProvider`, `searchNotesProvider`,
      `LIKE` push-down, dan level "blocker" temuan #1 reviewer
- [x] Keputusan per file tercatat (tabel §5)
- [x] Satu bug/halusinasi dibuktikan lewat grep/test — tanpa ini verifikasi dianggap belum dilakukan
- [x] Mampu menjelaskan tiap keputusan tanpa membuka AI (§9)
- [x] Uji manual 3 query + screenshot device asli (`screenshots/week9/`)

## 11. Refleksi

- **Halusinasi yang saya temukan:** `StateProvider` — dan yang lebih penting,
  klaim "sudah saya verifikasi" yang menyertainya. Cara membuktikannya bukan
  dengan menyangkal, tapi menjalankan analyze atas kode mentahnya lalu grep ke
  sumber package.
- **Prompt paling membantu:** slot **Batas** yang mengunci "hanya file fitur
  notes, tanpa dependensi baru". Slot itulah yang membuat temuan #3 terukur:
  batas yang jelas membuat klaim AI bisa dibantah dengan angka.
- **Refactor pada kode AI:** menghapus `searchNotesProvider`, dan mengganti
  `StateProvider` dengan `Notifier`.
- **Keputusan tersulit:** menerima desain filter in-memory AI obwohl jobsheet
  menyebut SQLite. Saya tolak push-down `LIKE`, dan jujur menyebutkan batas
  keputusan itu (§9) supaya tercatat sebagai pilihan yang bisa ditinjau, bukan
  sebagai kebenaran.
