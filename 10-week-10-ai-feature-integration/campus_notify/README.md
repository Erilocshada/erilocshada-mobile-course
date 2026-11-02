# Laporan Jobsheet #10 — Integrasi Fitur AI (campus_notify)

> Mata kuliah: Pemrograman Mobile · Minggu 10 · Project: `campus_notify`
> (base: hasil Minggu 8 — auth + FCM + pengumuman, Clean Architecture Minggu 7)
> Fitur baru: **Chat asisten AI (Gemini) + fallback lokal**
> Perangkat uji: OPPO CPH2269, Android 11 · Tanggal: 2 November 2026

**Daftar isi:**

1. [Apa yang dibangun](#apa-yang-dibangun)
2. [Arsitektur & keputusan teknis](#arsitektur--keputusan-teknis)
3. [Cara menjalankan](#cara-menjalankan)
4. [Hasil screenshot di perangkat asli](#hasil-screenshot-di-perangkat-asli)
5. [Bukti mesin hijau](#bukti-mesin-hijau)
6. [Tabel risiko & mitigasi](#tabel-risiko--mitigasi)
7. [Kebijakan AI & verifikasi](#kebijakan-ai--verifikasi)
8. [Refleksi](#refleksi)

---

## Apa yang dibangun

Satu fitur AI sesuai opsi modul (chat / OCR / STT): **chat asisten kampus**
di dalam `campus_notify`. Karena API key Gemini belum dimiliki, fitur ini
sengaja dibangun lengkap dengan **desain fallback** yang diminta modul —
tanpa key atau saat API error, asisten tetap menjawab dari data lokal
dengan badge "Mode offline", bukan layar error kosong.

Struktur mengikuti dependency rule Minggu 7 (`data -> domain <- presentation`):

```
lib/features/ai_chat/
├── domain/
│   ├── entities/chat_message.dart          # entity murni (+ flag isFallback)
│   ├── repositories/ai_chat_repository.dart # kontrak
│   └── usecases/ask_ai.dart                # validasi: tidak kosong, maks 400 char
├── data/
│   ├── ai_key_store.dart                   # API key di flutter_secure_storage
│   ├── gemini_api.dart                     # Dio + systemInstruction, parsing null-safe
│   ├── local_fallback.dart                 # jawaban lokal berbasis kata kunci
│   └── repositories/ai_chat_repository_impl.dart
└── presentation/
    ├── pages/chat_page.dart                # bubble chat, typing indicator, badge offline
    ├── pages/ai_settings_page.dart         # pasang/hapus API key
    └── providers/ai_chat_providers.dart    # wiring DI Riverpod (satu-satunya tempat)
```

## Arsitektur & keputusan teknis

- **API key tidak pernah ada di kode/Git** — disimpan di `flutter_secure_storage`
  lewat `AiKeyStore`, dipasang user dari menu Pengaturan AI (ikon kunci).
- **Hasil selalu record `({answer, isFallback, failure})`** — exception Dio/Socket
  tidak pernah mencapai presentation (pola Failure Minggu 7/8).
- **Prompt design** — system prompt membatasi persona, bahasa, panjang jawaban,
  dan melarang data pribadi; detail + alasan di [`docs/ai-log.md`](docs/ai-log.md).
- **Biaya & rate limit** — `maxOutputTokens: 300`, validasi panjang pertanyaan
  sebelum request, pertanyaan divalidasi use case.
- Modul codelab memakai `http` + model `gemini-pro`; saya ganti ke **Dio**
  (sudah dipakai project sejak Minggu 4) dan model **`gemini-2.0-flash`**
  karena `gemini-pro` sudah dihentikan Google — ini contoh verifikasi output
  modul, bukan terima mentah.

## Cara menjalankan

```bash
cd 10-week-10-ai-feature-integration/campus_notify
flutter pub get
flutter run -d <device>        # atau: flutter build apk --debug
```

Login bebas (email berisi `@`, password ≥ 6 karakter). Buka card
**"Asisten AI Kampus"** di Beranda.

## Hasil screenshot di perangkat asli

Semua diambil dari **OPPO CPH2269 (Android 11)** via `adb screencap` — folder [`screenshots/week10/`](screenshots/week10/):

| File | Membuktikan |
|---|---|
| `01-home-entri-ai.png` | Entri fitur "Asisten AI Kampus" di Beranda (integrasi dengan app Minggu 6–8) |
| `02-chat-page.png` | Halaman chat + banner status "API key AI belum diatur — jawaban dari data lokal" |
| `03-chat-fallback-jawaban.png` | Tanya "kapan jadwal UTS" tanpa key → jawaban data lokal + badge **Mode offline** (aplikasi tetap berguna, tidak error) |
| `04-pengaturan-apikey.png` | Pengaturan API key — status "Belum diatur", input tersembunyi, helper teks sumber key |
| `05-chat-error-apikey-fallback.png` | **Jalur error**: key palsu disimpan → Gemini menolak → tetap fallback ramah + Mode offline, tanpa crash |

## Bukti mesin hijau

Perintah dijalankan di root project ini, hasil 2 November 2026:

```
$ flutter analyze
Analyzing campus_notify...
No issues found! (ran in 7.0s)

$ flutter test
00:02 +23: ... CampusNotifyApp smoke test
00:02 +24: All tests passed!
```

**24 test lulus** — termasuk 10 test baru untuk fitur AI:

- `test/ai_chat/ask_ai_test.dart` — pertanyaan kosong / kepanjangan ditolak
  **sebelum** repository dipanggil; input di-trim.
- `test/ai_chat/ai_chat_repository_test.dart` — 6 skenario lewat Dio adapter
  stub tanpa jaringan: tanpa key → fallback; respons valid → jawaban LLM;
  HTTP 500 → fallback; `candidates` kosong → fallback; diblokir safety →
  fallback; key salah (401) → pesan menyebut Pengaturan AI.
- `test/ai_chat/chat_page_widget_test.dart` — UI mengirim pesan, menampilkan
  badge Mode offline, dan menolak kirim pesan kosong.

## Tabel risiko & mitigasi

| Risiko | Implementasi mitigasi di kode |
|---|---|
| Bocor data pengguna | Hanya teks pertanyaan yang dikirim; system prompt melarang NIK/telepon/alamat; sesi login tidak ikut terkirim (dibaca di request body `GeminiApi.generate`) |
| API key terbaca di repo | Key hanya di `flutter_secure_storage` via menu Pengaturan — tidak ada di kode, git, atau `pubspec` |
| Biaya melonjak | `maxOutputTokens: 300`, pertanyaan dibatasi 400 karakter, tidak ada retry otomatis; cache lokal bisa ditambahkan (sudah dipisah lewat `LocalFallback`) |
| API error / down | Semua `DioException`/`SocketException` → fallback data lokal + badge Mode offline (terbukti di screenshot 05) |
| Respons tidak relevan / kosong | Parsing null-safe; `candidates` kosong atau diblokir safety dianggap tidak valid → fallback (tertest) |

## Kebijakan AI & verifikasi

AI coding assistant (Qoder CLI) membantu merancang dan menulis fitur ini.
Sesuai kebijakan Minggu 9–10, yang dinilai adalah **verifikasi**, dan itu
terdokumentasi di [`docs/ai-log.md`](docs/ai-log.md): setiap baris dibaca,
endpoint modul yang usang dikoreksi, 3 error nyata hasil ronde verifikasi
pertama (path import, constructor field, signature `close`) ditangkap
analyzer sebelum demo, dan perilaku fallback dibuktikan di test + perangkat.

## Refleksi

1. **Fitur yang dipilih: chat** — paling relevan untuk aplikasi pengumuman
   (menjawab pertanyaan seputar jadwal/notifikasi) dan bisa didemokan end-to-end
   termasuk sisi error-nya.
2. **Privasi**: kunci desain adalah memisahkan apa yang dikirim ke LLM (hanya
   pertanyaan) dari apa yang dimiliki aplikasi (token sesi, topik langganan) —
   plus larangan eksplisit di system prompt.
3. **Fallback yang disediakan**: dua lapis — belum ada key (tanpa panggilan
   jaringan sama sekali) dan API gagal (error apa pun). Keduanya tertest dan
   terscreenshot di device asli.
4. **Pelajaran UX fitur AI di mobile**: pengguna tidak butuh tahu bahwa API
   error — mereka butuh tetap dapat jawaban. Badge "Mode offline" memberi
   transparansi tanpa menghentikan alur; indikator typing dan input-lock
   mencegah spam request (yang juga biaya).
