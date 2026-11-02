# AI Review vs Keputusan Final — Jobsheet #08 (AI Challenge)

> Project: `campus_notify` · 27 Oktober 2026
> Aturan yang saya pegang: AI boleh jadi reviewer awal, **keputusan final tetap milik saya**, dan setiap temuan harus terbukti dengan grep / test merah / reproduksi sebelum diterapkan.

## 1. Prompt yang saya berikan

```
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

Objek review: diff branch `feat/week8-review-discipline` terhadap snapshot minggu 7 (`c118ad6`).

## 2. Output awal AI (5 temuan, apa adanya)

1. **[blocker]** `SignIn.call()` melakukan null-cases `result.session!` — kontrak record `(session, failure)` tidak menjamin salah satu non-null, jadi implementasi `AuthRepository` lain yang mengembalikan `(null, null)` membuat use case crash.
2. **[blocker]** Smoke test `widget_test.dart` me-`pumpWidget(CampusNotifyApp())` tanpa override DI, sehingga `HomePage` → `pushRepositoryProvider` → `FirebaseMessaging.instance` dipanggil di environment test dan meledak `[core/no-app]`.
3. **[saran]** Semua 20 file `lib/` + `test/` tidak seragam gaya formatnya terhadap Dart SDK saat ini; usul "perbaiki manual satu-satu sambil review".
4. **[saran]** Ganti semua return `(T?, Failure?)` menjadi sealed `Result<T>` / `Either<Failure,T>` (fpdart) agar state lebih type-safe.
5. **[saran]** `ApiClient.onError` sebaiknya digembok dengan `Completer`/mutex supaya request 401 paralel tidak memicu refresh token berkali-kali.

## 3. Verifikasi & keputusan saya (tabel utama)

| # | Temuan AI | Verifikasi yang saya lakukan | Keputusan | Bukti |
|---|---|---|---|---|
| 1 | Null-cases `result.session!` di `SignIn` | Saya tulis test `SignIn tidak crash saat repository melanggar kontrak` memakai `FakeAuthRepository(nullSession: true)`, jalankan sebelum fix | **DITERIMA (blocker)** — perbaiki dengan guard eksplisit + `AuthFailure` ramah, bukan `!` | Test **merah sebelum fix**: `Null check operator used on a null value  sign_in.dart 27:35`; **hijau setelah fix** (`f6d74c5`). Test permanen ada di `test/auth/sign_in_test.dart` |
| 2 | Smoke test menyentuh Firebase/SecureStorage asli | reproduce: `flutter test` sebelum fix | **DITERIMA (blocker)** — `pushRepositoryProvider` di-override dengan `FakePushRepository`, `tokenStoreProvider` dengan `FakeTokenStore`. Ini justru membuktikan klaim minggu 7 "titik wiring tunggal mudah di-fake" | Test **merah sebelum fix**: `ProviderException ... [core/no-app] No Firebase App '[DEFAULT]' has been created`; hijau setelah override (12/12 lulus) |
| 3 | Rapikan 20 file **manual saat review** | jalankan `dart format --output=none --set-exit-if-changed .`: gagal dengan 20 file berubah; diff `git diff` saya periksa = murni folding baris, nol perubahan perilaku | **DITOLAK bentuknya, DIDELEGASIKAN ke mesin** — diperbaiki dengan `dart format` otomatis (commit `5650d72`) lalu dijaga CI, bukan dikomentari manual. Review manusia untuk hal ini = "review debat spasi", persis error umum di jobsheet | `style(week8)` commit + langkah `dart format` di `ci.yml`; nol beda perilaku (test tetap lulus) |
| 4 | Ganti record `(T?, Failure?)` dengan fpdart `Either` | cek `pubspec.yaml` (tidak ada fpdart), cek keputusan minggu 7 | **DITOLAK** — sama dengan keputusan minggu 7 (`docs/AI_CHALLENGE.md`): dependensi baru tak sepadan untuk CRUD sederhana; record Dart sudah eksplisit dan domain tetap murni. Tidak melanggar dependency rule, tapi over-engineering untuk scope ini | Tidak ada perubahan dependensi; analyzer bersih |
| 5 | Mutex `Completer` untuk refresh paralel di `ApiClient` | grep: `ApiClient` **belum dipakai oleh siapa pun** (`grep -rn "ApiClient(" lib/` → nol pemanggil; backend masih mock, 401 asli tidak pernah terjadi) | **DITOLAK SEKARANG, DITERIMA SEBAGAI TEKAN TEKNIS** — menambah lock pada jalur yang belum punya caller = kompleksitas spekulatif + mustahil diuji jujur sekarang. Dicatat di `review-checklist.md` §5 untuk dikerjakan saat backend sungguhan masuk | Hasil grep; `api_client.dart` hanya direferensikan komentarnya sendiri |

## 4. Ringkasan sesuai syarat AI Challenge

- Temuan AI terbukti benar dan **diterapkan**: #1 dan #2 — dua-duanya blocker kebenaran, masing-masing dibuktikan dengan test yang **merah sebelum fix dan hijau sesudahnya** (bukan asumsi).
- Temuan AI yang **saya tolak dengan alasan tertulis**: #4 (over-engineering, konsisten dengan keputusan minggu 7), #5 (jalur mati, kompleksitas spekulatif), serta bentuk pelaksanaan #3 (delegasi ke formatter + CI, bukan review manusia).
- Tidak ada usulan AI yang melanggar dependency rule (domain tetap tidak mengimpor Flutter/Dio/Firebase) — diverifikasi ulang dengan grep sterilitas minggu 7 (`docs/GREP_VERIFICATION.md`).
