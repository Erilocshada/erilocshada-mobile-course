# AI Log — Minggu 10: Integrasi Fitur AI (Chat Asisten)

Project: `campus_notify` · Fitur: chat asisten Gemini + fallback lokal
Perangkat uji: OPPO CPH2269 (Android 11) · Tanggal: 2 November 2026

Sesuai kebijakan AI modul: AI boleh membantu merancang & mengimplementasi,
tetapi setiap baris dibaca, API diverifikasi, dan hasil diuji. Log ini
merekam prompt, output awal, dan verifikasi yang saya lakukan.

---

## 1. Prompt design yang diterapkan (fitur chat)

### System prompt (persona + batas) — `lib/features/ai_chat/data/gemini_api.dart`

> Kamu adalah asisten kampus "Campus Notify" untuk mahasiswa Indonesia.
> Jawab dalam Bahasa Indonesia, maksimal 3 kalimat, ramah dan spesifik.
> Jangan pernah meminta atau menampilkan data pribadi (NIK, telepon,
> alamat). Jangan beri jawaban di luar konteks layanan kampus.

Alasan tiap klausul:

| Klausul | Tujuan |
|---|---|
| "asisten kampus Campus Notify" | batasi topik → mengurangi halusinasi di luar konteks |
| "Bahasa Indonesia, maks 3 kalimat" | UX mobile: bubble pendek, mudah dibaca |
| "jangan NIK/telepon/alamat" | perlindungan privasi (tabel risiko modul poin 1) |
| "maksOutputTokens: 300" | kontrol biaya per request (tabel risiko poin 2) |

### User prompt

Input bebas dari pengguna, dibatasi use case `AskAi`:
tidak boleh kosong, maksimal 400 karakter (divalidasi SEBELUM sampai API).

### Privasi

Yang dikirim ke AI API hanya teks pertanyaan user. Tidak ada token sesi,
email, NIM, atau data lokal lain yang ikut dikirim (diverifikasi dengan
membaca request body di `GeminiApi.generate`).

---

## 2. User prompt & output awal saat demo (perangkat asli)

Demo dijalankan di OPPO CPH2269 — lihat `screenshots/week10/`.

**Ronde A — tanpa API key (fallback murni, `03-chat-fallback-jawaban.png`):**

- User prompt: `kapan jadwal UTS`
- Output aplikasi (data lokal, badge "Mode offline"):
  > Jadwal Ujian Tengah Semester telah diumumkan. Silakan cek jadwal melalui
  > sistem akademik (lihat menu Pengumuman #1).
- Verifikasi: tidak ada request jaringan yang terjadi (jalur `apiKey == null`
  pada `AiChatRepositoryImpl.ask` keluar sebelum memanggil Dio — tertest di
  `ai_chat_repository_test.dart` "tanpa API key").

**Ronde B — API key palsu disimpan (jalur error, `05-chat-error-apikey-fallback.png`):**

- User prompt: `cara langganan pengumuman`
- Gemini menolak key (`HTTP 400`) → output aplikasi:
  > Pengumuman kampus tersedia di menu Pengumuman. Aktifkan langganan topik
  > "pengumuman-kampus" di Beranda agar notifikasinya masuk otomatis. [Mode offline]
- Verifikasi: aplikasi tidak crash dan tidak menampilkan exception mentah;
  waktu respons ±5 detik = bukti request sungguhan keluar lalu gagal dengan
  anggun. Key kemudian dihapus lewat menu yang sama (snackbar "API key
  dihapus — kembali ke mode offline").

## 3. Penggunaan AI coding assistant (kebijakan minggu 9–10)

- AI (Qoder CLI) membantu merancang struktur `ai_chat` mengikuti pola
  minggu 7 (record result `({answer, isFallback, failure})`, NOTIFIER
  Riverpod, secure storage meniru `TokenStore`).
- Keputusan teknis yang saya verifikasi sendiri, bukan terima mentah:
  1. Modul codelab memakai endpoint `gemini-pro` + paket `http` — saya
     ganti ke `gemini-2.0-flash` + Dio karena model `gemini-pro` sudah
     dihentikan Google dan Dio sudah dipakai project ini sejak minggu 4.
  2. Contoh modul `throw Exception` dan parsing `candidates[0]` tanpa
     check — diganti record Failure + parsing null-safe karena minggu 8
     melarang exception mentah mencapai presentation.
  3. Contoh modul menyimpan API key tanpa pembungkus — dibuat `AiKeyStore`
     terpisah agar presentation tidak menyentuh plugin (testable, sama
     seperti alasan `SessionRepository`).
- Hasil error nyata dari ronde verifikasi pertama: salah path import
  (`../domain` dari `data/repositories` harusnya `../../domain`),
  constructor tidak meng-assign field, dan override
  `HttpClientAdapter.close` kurang parameter `force` → analyzer menangkap
  ketiganya sebelum satu baris pun dijalankan di device.

## 4. Bukti verifikasi

- `flutter analyze` → No issues found (lihat README bagian mesin hijau).
- `flutter test` → 24 lulus, termasuk 6 test repository AI yang memaksa
  kondisi error API (HTTP 500, 401, candidates kosong, safety-block) lewat
  Dio adapter stub — membuktikan fallback bekerja tanpa jaringan asli.
- Demo perangkat (screenshot `screenshots/week10/`): tanpa API key, chat
  tetap menjawab dari data lokal dengan badge "Mode offline" — aplikasi
  tidak pernah menampilkan layar error kosong.
