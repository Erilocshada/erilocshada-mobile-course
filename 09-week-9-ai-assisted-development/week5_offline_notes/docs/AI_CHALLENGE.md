# AI Verification Challenge — Jobsheet #9

> Proyek: `09-week-9-ai-assisted-development/week5_offline_notes` · 30 Oktober 2026
> Objek: **fitur pencarian judul catatan yang sudah saya klaim selesai** (commit `d13d983`),
> di-review oleh AI lain yang tidak ikut menulis kode dan tidak tahu isi dokumen ini.
> Aturan yang saya pegang: klaim AI adalah hipotesis sampai ada bukti — grep, test merah,
> atau perintah yang bisa diulang.

Bedanya dengan `docs/ai-log.md`: di sana AI berperan sebagai **produser** kode dan saya
verifikasi drafnya. Di sini AI berperan sebagai **reviewer**, dan yang diverifikasi adalah
klaimnya tentang kode saya sendiri. Ini bagian tersulit dari jobsheet #9, karena godaan
"temuanku pasti benar" jauh lebih besar saat kodenya milikku.

---

## 1. Prompt yang saya berikan

Prompt kedua pada jobsheet: *"Review kode search Flutter ini sebagai senior dev ... Beri 3
temuan + level"*. Saya pakai teks itu apa adanya, lalu menambah konteks jalur + aturan yang
mempersulit AI berhalusinasi (read-only, wajib menyebut sumber klaim, dilarang menyamakan
selera dengan bug):

```
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data), Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.

Kode yang di-review ada di proyek Flutter: D:/KULIAH/SMT-5/Pemmob/09-week-9-ai-assisted-development/week5_offline_notes

File yang relevan dengan fitur pencarian judul catatan (baca ini):
- lib/features/notes/domain/usecases/search_notes.dart
- lib/features/notes/presentation/providers/note_providers.dart
- lib/features/notes/presentation/pages/notes_page.dart
- lib/features/notes/domain/repositories/note_repository.dart
- lib/features/notes/data/repositories/note_repository_impl.dart
- test/features/notes/search_notes_test.dart
- test/features/notes/filtered_notes_provider_test.dart
- test/features/notes/notes_search_widget_test.dart
- test/features/notes/fake_note_repository.dart

Aturan:
- READ-ONLY. Jangan menulis, membuat, atau mengubah file apa pun, dan jangan menjalankan
  perintah yang memodifikasi proyek. Cukup laporkan temuan sebagai teks.
- Beri tepat 3 temuan, masing-masing dengan level (blocker atau saran) dan alasan teknis
  yang spesifik.
- Kalau kamu mengklaim sebuah API tidak ada atau berperilaku berbeda dari dugaan, sebutkan
  dari mana kamu tahu (nama file/baris di pub cache, atau perintah yang kamu jalankan)
  supaya klaimnya bisa diverifikasi.
- Jangan menyamakan selera penulisan dengan bug; fokus ke kebenaran dan arsitektur seperti
  diminta.
```

## 2. Output AI (verbatim, tidak disunting)

Dua hal yang saya perhatikan sebelum membaca temuannya: AI itu **membuka diri dengan
menandai asumsinya sendiri** — klaim LIKE SQLite dan klaim keyboard iOS menghasilkan NFD
dinyatakan eksplisit sebagai "perilaku terdokumentasi umum ... TIDAK saya jalankan di
lingkungan ini", bukan dijual sebagai fakta. Persis disiplin yang jobsheet minta, dan itu
membuat klaimnya mudah saya tagih.

> **Temuan 1 — Kebenaran (Blocker): `filteredNotesProvider` menelan query saat sumber data
> error, dan jalur itu tidak dijamin kontraknya.**
> Lihat `note_providers.dart:124-129`: `ref.watch(notesProvider).whenData(...)` saat error
> mengembalikan `AsyncError` apa adanya, sehingga query aktif "diam-diam" diabaikan. Ini
> sebenarnya perilaku yang bisa diterima — tapi masalahnya adalah tidak ada satu pun test
> yang mengikat kontrak ini. Untuk milestone yang premisnya persisnya "hasil AI yang sudah
> diverifikasi" (commit `d13d983`), menerima branch error tanpa test = hasil AI belum
> diverifikasi untuk cabang tersebut. Ini blockers terhadap acceptance criteria, bukan selera.
>
> **Temuan 2 — Arsitektur (Saran): dua "sumber kebenaran" untuk teks pencarian tidak pernah
> disinkronkan.**
> `NoteSearchField` memakai `TextEditingController` sebagai sumber tampilan
> (`notes_page.dart:57, 74`) sementara `noteSearchQueryProvider` sebagai sumber penyaringan
> (`note_providers.dart:113`, dibaca di `notes_page.dart:29, 67`). Keduanya hanya kebetulan
> konsisten karena SATU-SATUNYA penulis provider adalah `onChanged` dan tombol clear, dan
> keduanya juga menyentuh controller. Provider ini hidup sepanjang sesi (app-scope
> `ProviderScope`, non-autoDispose). Begitu `NoteSearchField` di-remount sementara provider
> masih menyimpan nilai (mis. perubahan `key`, atau suatu saat ada `setQuery` programatik
> dari luar field), yang tampil adalah kolom kosong DI ATAS daftar yang masih terfilter,
> plus ikon "clear" (X) yang muncul palsu (`notes_page.dart:77`). Aman hari ini, rapuh
> secara desain. Solusi bersih: jadikan field *controlled* (satu sumber kebenaran) atau
> inisialisasi `_controller.text` dari provider di `initState`.
>
> **Temuan 3 — Test (Saran): test aksen mengunci generalisasi yang salah, dan test
> "ditempel apa adanya" tidak menutup jalur yang penting.**
> `search_notes.dart:10-12` memakai `.trim().toLowerCase()` — ini menangani
> case-insensitivity dengan benar (keputusan menolak push-down `LIKE` memang tepat, sesuai
> alasan author bahwa LIKE SQLite hanya case-insensitive untuk ASCII), tetapi TIDAK
> menormalkan Unicode. Judul NFD (`e` + combining acute) vs query NFC (`é` precomposed,
> U+00E9) tidak akan `contains` walau keduanya tampil "é" identik dan sama-sama sudah
> di-lowercase. Test `search_notes_test.dart:49-61` lolos hanya karena kedua sisi memakai
> bentuk normal yang sama, sehingga ia menguji properti yang tidak berlaku umum (kalau
> asumsi NFD-iOS saya benar, ini miss nyata di perangkat). Selain itu kedua test AI yang
> "ditempel apa adanya" (`search_notes_test.dart:5`, `notes_search_widget_test.dart:10`)
> tidak menyentuh: tombol clear (X), propagasi error (`notesPage` `LoadError` + `Coba
> Lagi`, `notes_page.dart:168-188`), dan persistensi query melewati mutasi (`_mutate`
> mengeset `state=loading` di `note_providers.dart:63` sehingga hasil terfilter flash ke
> spinner — tak ada test yang memastikan query tetap terpakai setelah re-fetch). Untuk
> klaim "verified", cabang-cabang ini perlu diuji.

## 3. Verifikasi tiap temuan — test ditulis lebih dulu, keputusan belakangan

Sesuai aturan jobsheet saya tidak langsung menuruti reviewer. Untuk tiap temuan saya tulis
testnya **lebih dulu**, jalankan terhadap kode yang ada, lalu putuskan dari hasilnya.
Empat test state itu jadi satu file baru: `test/features/notes/note_search_state_test.dart`.

| # | Klaim AI | Cara saya membuktikan | Hasil | Keputusan |
|---|---|---|---|---|
| 1 | `whenData` menelan query saat error — **blocker** | Test: `FakeNoteRepository(failOnFetch: true)`, ketik `ker`, periksa apa yang dirender halaman | **Lulus tanpa saya ubah apa pun.** Yang tampil tetap `Gagal memuat catatan`, dan `Tidak ada catatan yang cocok` berstatus `findsNothing` | **LEVEL DITOLAK, ISINYA DITERIMA.** Perilakunya benar — `whenData` hanya mentransformasi cabang data, `AsyncError`/`loading` lewat tanpa perubahan, jadi pengguna tidak pernah disuguhi "0 hasil" yang menipu. Menyebut ini blocker = salah label. Tapi bagian "tidak ada test yang mengikat kontrak" benar, dan testnya saya tambahkan |
| 2 | controller & provider = dua sumber kebenaran yang tak pernah disinkronkan — **saran** | Test: `pumpPage(key:'a')` → `enterText('ker')` → `pumpPage(key:'b')` (State `NoteSearchField` dibuang, provider app-scope tetap hidup), lalu baca `controller.text` | **MERAH sebelum fix:** `Expected: 'ker'  Actual: ''`, reason "kolom kosong di atas daftar yang masih terfilter". Hijau setelah fix | **DITERIMA.** Ini temuan AI yang terbukti benar pada kode saya dan saya perbaiki |
| 3a | `.trim().toLowerCase()` tidak menormalkan Unicode | Skrip Dart sementara (`dart run`, di luar repo, sudah saya hapus) membandingkan `'R\u00e9sum\u00e9'` NFC vs `'Re\u0301sume\u0301'` NFD | **Benar secara faktual:** `panjang NFC 12, panjang NFD 14`; `nfc == nfd ? false`; `query NFC vs judul NFD : false`. Case-folding non-ASCII justru jalan: `huruf Yunani Σ vs σ : true` | **BENAR tapi TIDAK diperbaiki.** Normalisasi NFC/NFD butuh dependensi; slot **Batas** prompt melarang menambah dependensi, dan jobsheet #9 tidak menuntut pencarian Unicode-aware. Premis pemicunya ("keyboard iOS menulis NFD") oleh si AI sendiri ditandai sebagai asumsi tak terverifikasi, dan judul di app ini ditulis lewat keyboard yang sama dengan keyboard pencarian. Batasnya saya kunci sebagai test dokumentasi, bukan saya diamkan |
| 3b | tombol clear belum diuji | Test clear button pada kode yang ada | **LULUS** — `_controller.clear()` + `setQuery('')` sudah mengembalikan seluruh daftar dan menghilangkan ikon X | **KLAIM UJI BENAR, JALURNYA SEHAT.** Test tetap disimpan supaya klaimnya tidak lagi benar |
| 3c | propagasi error belum diuji | Sama dengan test temuan #1 | **LULUS**, `LoadError` tampil dan tidak berubah menjadi empty state | **DITERIMA sebagai kekurangan test**, bukan bug |
| 3d | query belum diuji tetap terpakai melewati `_mutate` | Test: ketik `kerja`, panggil `addNote('Kerja bakti')` lewat `ProviderScope.containerOf`, `pumpAndSettle`, periksa daftar + isi kolom | **LULUS.** `state = const AsyncValue.loading()` tidak menyentuh `noteSearchQueryProvider` (provider berbeda, tidak di-`invalidate`), jadi query bertahan; `Kerja bakti` muncul, `Belanja mingguan` tetap tersaring, kolom masih `kerja` | **DITOLAK sebagai bug, DITERIMA sebagai lubang test.** Tidak ada perubahan kode, hanya test penutup kontrak |

### 3.1 Bukti merah → hijau untuk temuan #2

Sebelum fix (test #2 gagal, dua lainnya hijau):

```text
00:00 +0: temuan #2 reviewer: query tetap tampil di kolom setelah halaman di-remount
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞═══
The following TestFailure was thrown running a test:
Expected: 'ker'
  Actual: ''
   Which: is different. Both strings start the same, but the actual value is missing the
trailing characters: ker
kolom kosong di atas daftar yang masih terfilter = dua sumber kebenaran yang tidak disinkronkan
...
00:02 +2 -1: Some tests failed.
```

Sesudah fix — controller ditumbuhkan dari provider, bukan dari string kosong:

```dart
late final TextEditingController _controller;

@override
void initState() {
  super.initState();
  _controller = TextEditingController(text: ref.read(noteSearchQueryProvider));
}
```

```text
00:00 +1: temuan #2 reviewer: query tetap tampil di kolom setelah halaman di-remount
00:01 +3: All tests passed!
```

`ref` pada `ConsumerState` tersedia di `initState`, jadi `initState` memang tempat yang sah
untuk baca sekali. Saya sengaja **tidak** mengubah field menjadi fully-controlled
(`controller.text = query` setiap rebuild) seperti opsi lain yang si AI sebut: itu membuang
posisi kursor saat pengguna mengetik cepat, dan untuk kebutuhan ini benih sekali sudah
menutup lubang sinkronisasinya.

### 3.2 Bukti mesin setelah semua perubahan

```text
$ flutter analyze
No issues found! (ran in 3.6s)

$ dart format .
Formatted 39 files (1 changed) in 0.10 seconds

$ flutter test
00:04 +22: All tests passed!
```

Dari 17 test sebelum challenge menjadi **22 test** sesudahnya: 4 test state baru + 1 test
batas Unicode di `search_notes_test.dart`. Tidak ada test yang saya lemahkan; satu-satunya
test yang gagal adalah test yang memang saya tulis untuk mereproduksi temuan #2.

## 4. Ringkasan sesuai syarat jobsheet #9

- **≥1 temuan AI terbukti benar lalu diperbaiki** → temuan **#2** (dua sumber kebenaran
  pencarian). Buktinya test merah `Expected: 'ker' Actual: ''` sebelum fix, hijau sesudah
  `initState` menumbuhkan `_controller` dari `noteSearchQueryProvider`.
- **≥1 temuan AI ditolak dengan alasan teknis tertulis** → tiga, dengan tiga rasa berbeda:
  - temuan **#1 ditolak pada levelnya**: bukan blocker, karena `whenData` hanya mengubah
    cabang data dan `AsyncError` lewat utuh sehingga halaman tetap menampilkan error, tidak
    pernah menampilkan "tidak ada hasil". Dibuktikan test yang langsung lulus.
  - temuan **#3a benar tapi tidak diperbaiki**: normalisasi NFC/NFD di luar batas prompt
    (tanpa dependensi baru), dan premis pemicunya dinyatakan asumsi oleh AI itu sendiri.
    Batasnya kini dikunci test dokumentasi, bukan dibisikkan.
  - temuan **#3d ditolak sebagai bug**: query ternyata bertahan melewati `_mutate`, tetapi
    tidak ada test yang menjaminkannya — jadi yang saya tambah testnya, bukan kodenya.
- **Yang membuat saya tidak nyaman, dan itu bagus:** reviewer asing menemukan bug nyata di
  kode yang **sudah saya tulis dan sudah saya klaim terverifikasi** (temuan #2). Kesimpulan
  yang jujur: verifikasi saya waktu itu belum mencakup siklus hidup State widget, hanya
  alur ketik-normal. Test `note_search_state_test.dart` adalah tambalannya, dan ia lahir
  dari AI, bukan dari saya.

## 5. Jawaban tanpa membuka AI

Kalau ditanya di depan kelas kenapa `_controller` diberi benih dari provider:

> Provider query ber-scope aplikasi (`ProviderScope` di `main.dart`, non-autoDispose),
> sedangkan `_NoteSearchFieldState` ber-scope halaman dan bisa dibuang kapan saja saat
> widget-nya di-remount — misalnya ketika kembali dari halaman detail catatan. Kalau
> controller ditumbuhkan dari string kosong, hasil remount adalah kolom kosong di atas
> daftar yang masih terfilter, dan ikon clear yang muncul padahal kolomnya kosong: dua
> sumber kebenaran yang cuma kebetulan konsisten selama satu-satunya penulis keduanya
> adalah `onChanged` field itu sendiri. Karena itu controller diberi benih sekali di
> `initState` dari nilai provider, supaya State baru mulai dari keadaan yang benar; saya
> tidak menjadikannya controlled penuh agar posisi kursor tidak rusak saat mengetik.

Kenapa normalisasi Unicode tidak saya kerjakan:

> `toLowerCase()` melakukan case folding (huruf Yunani besar/kecil pun cocok, saya cek),
> tetapi bukan normalisasi, jadi `é` precomposed dan `e` + combining acute dianggap beda.
> Itu nyata, tetapi membetulkannya butuh normalisasi NFC/NFD lewat paket pihak ketiga, dan
> prompt-nya sendiri melarang menambah dependensi. Untuk catatan yang judulnya diketik dan
> dicari di perangkat yang sama, biaya normalisasi tidak sepadan dengan risikonya; saya
> kunci perilakunya lewat test `bates: judul NFD tidak cocok dengan query NFC` supaya
> batasnya tercatat, bukan tersembunyi.
