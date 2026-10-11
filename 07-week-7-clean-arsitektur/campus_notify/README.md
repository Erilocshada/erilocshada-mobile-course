# Laporan Jobsheet #07 — Clean Architecture (campus_notify)

> Mata kuliah: Pemrograman Mobile · Minggu 7 · Project: `campus_notify`
> (auth + FCM + pengumuman) · Perangkat uji: OPPO CPH2269, Android 11

Saya merefactor project Minggu 6 saya, `campus_notify` (auth + FCM + pengumuman),
menjadi Clean Architecture feature-first. Laporan ini saya tulis bertahap
per praktikum sesuai codelab.

**Daftar isi:**

1. [Praktikum 1 — Audit layer project lama](#praktikum-1--audit-layer-project-lama)
2. [Praktikum 2 — Domain dan data per fitur](#praktikum-2--domain-dan-data-per-fitur)
3. [Praktikum 3 — Presentation, DI, dan verifikasi](#praktikum-3--presentation-di-dan-verifikasi)
4. [Refactoring Challenge & Testing](#refactoring-challenge--testing)
5. [Laporan akhir](#laporan-akhir) — struktur final, arah dependensi, screenshot, checklist

## Praktikum 1 — Audit layer project lama

### 1. Peta file ke layer (sebelum refactor)

| File | Layer saat ini | Masalah yang saya temukan |
|---|---|---|
| `pages/home_page.dart` | presentation | Mengimpor provider yang meneruskan `PushService` konkret — Firebase/Dio/SecureStorage bocor transitif ke widget; logika subscribe topic bercampur dengan state widget |
| `pages/login_page.dart` | presentation | Menerima `e.toString()` (exception mentah) dari notifier, bukan pesan ramah |
| `pages/announcement_page.dart` | presentation | Data hardcoded di `build()` — tidak lewat repository sama sekali |
| `providers/auth_provider.dart` | presentation (state) | Notifier memanggil concretion `AuthRepository` & `TokenStore` langsung; `AuthRepository()` diinstansiasi manual |
| `providers/push_provider.dart` | presentation (DI) | Mengekspos class infra konkret ke widget |
| `data/api_client.dart` | data | Bergantung concretion (bukan abstraksi domain); tidak dipakai siapa-siapa (dead code) |
| `data/api_errors.dart` | data | Menghasilkan String, bukan objek `Failure` domain |
| `data/auth_repository.dart` | data (+kontrak tercampur) | Interface & implementasi satu kelas; entity `AuthSession` hidup di data; validasi melempar `Exception` |
| `data/token_store.dart` | data | OK, tapi dipakai langsung oleh presentation (via notifier) |
| `messaging/push_service.dart` | data/infra | 436 baris melanggar SRP (permission+channel+token+HTTP+routing); mengimpor `GoRouter` — infra tahu presentation |

### 2. Tiga grep pelanggaran klasik (di project lama)

```
$ grep -rEn "Dio\(|http\.|openDatabase|SharedPreferences\.getInstance|FlutterSecureStorage" lib/pages lib/widgets
(nol hasil langsung — TAPI lewat import push_provider, widget tetap tersambung ke FlutterSecureStorage/Dio transitif)

$ grep -rEn "DateFormat|jsonDecode|\.toIso8601String" lib/pages lib/widgets
(nol hasil)

$ grep -rEn "Repository\(|Dio\(BaseOptions" lib/pages lib/providers
lib/providers/auth_provider.dart:15:    return AuthRepository();
```

Temuan saya: pelanggaran terbesar bukan teks di widget, melainkan **arah
dependensi** — presentation mengimpor infra konkret
(`providers/push_provider.dart` → `messaging/push_service.dart`,
`providers/auth_provider.dart` → `data/auth_repository.dart` + `data/token_store.dart`).

### 3. Struktur target yang saya rencanakan

```
lib/
├── core/
│   ├── failures.dart        # Failure domain (murni Dart)
│   └── format.dart          # fungsi murni lintas fitur
├── features/
│   ├── auth/         domain/{entities,repositories,usecases}  data/{models,repositories}  presentation/{providers,pages}
│   ├── announcements/   (pola sama)
│   ├── push/            (interface di domain, Firebase/Dio terkunci di data)
│   └── home/            presentation saja (screen komposit)
├── main.dart
└── routes.dart
```

Saya tidak membuat fitur baru — hanya memindahkan dan memisahkan kode yang
sudah jalan. Snapshot commit `chore: snapshot before clean architecture`
sudah saya buat sebelum menyentuh kode.

## Praktikum 2 — Domain dan data per fitur

Saya buat layer **domain** lebih dulu (inti yang stabil), baru **data** yang
menyambungkannya ke Dio/SQLite/secure storage. File lama sengaja belum saya
hapus — saya pindahkan bertahap supaya aplikasi tetap bisa dibandingkan.

### Yang saya buat

1. `lib/core/failures.dart` — `sealed class Failure` + `ValidationFailure`,
   `AuthFailure`, `NetworkFailure`, `LocalFailure`. Murni Dart, tanpa import framework.
2. `lib/core/format.dart` — fungsi murni hasil ekstraksi dari file infra lama:
   `maskToken()`, `routeFromMessage()`, dan `formatDate()` (biar bisa diuji tanpa widget).
3. **auth** — `domain/entities/auth_session.dart` (entity murni, tanpa mapping),
   `domain/repositories/auth_repository.dart` + `session_repository.dart` (kontrak),
   `domain/usecases/sign_in.dart`, `data/models/auth_session_model.dart`
   (fromJson HANYA di model), `data/repositories/auth_repository_impl.dart`
   (validasi lama yang dulu `throw Exception` sekarang mengembalikan
   `ValidationFailure`), `data/repositories/session_repository_impl.dart`,
   `data/token_store.dart`, `data/api_client.dart` (di-refactor: interceptor
   sekarang bergantung abstraksi domain, bukan concretion).
4. **announcements** — entity `Announcement`, interface repository,
   `GetAnnouncement` (aturan bisnis: validasi id), `AnnouncementModel.fromJson`,
   impl mock dengan data yang sama seperti minggu 6.
5. **push** — interface `PushRepository` + konstanta `PushTopics` di domain;
   `PushServiceImpl` (data) mengimplementasikannya — seluruh import
   Firebase/Dio/SecureStorage kini TERKUNCI di layer data.

### Keputusan penting

- Kontrak repository saya taruh di **domain** karena domain yang menentukan
  APA yang dibutuhkan; data layer yang menentukan BAGAIMANA.
- Hasil sukses/gagal memakai **record Dart** `({T? x, Failure? failure})`
  seperti contoh codelab — bukan exception, supaya tidak ada yang bocor ke UI.
- `SignIn` saya jadikan use case karena mengorkestrasi 2 repository
  (login + simpan sesi). Untuk CRUD satu baris saya TIDAK membuat use case
  (alasan lengkap di laporan AI Challenge nanti).

## Praktikum 3 — Presentation, DI, dan verifikasi

### Wiring DI (satu-satunya tempat layer disatukan)

Riverpod murni, tanpa package DI tambahan:

- `features/auth/presentation/providers/auth_providers.dart` —
  `tokenStore → SessionRepository → AuthRepository → SignIn → AuthNotifier`.
  Notifier sekarang memanggil use case/repository lewat abstraksi, tidak ada
  lagi `AuthRepository()` di luar provider dan tidak ada lagi `e.toString()`.
- `features/announcements/presentation/providers/announcement_providers.dart` —
  `announcementProvider` (list) + `announcementDetailProvider` (family per id).
- `features/push/presentation/providers/push_providers.dart` —
  `Provider<PushRepository>`; widget hanya mengenal interface.

### Halaman hanya membaca state

`announcement_page.dart` saya ubah dari teks hardcoded menjadi `ConsumerWidget`
dengan `state.when(loading/error/data)` + tombol retry (`ref.invalidate`).
`home_page.dart` sekarang memanggil `PushRepository` (interface), bukan
`PushServiceImpl`. Satu perubahan arah dependensi penting: `PushService` tidak
lagi menerima `GoRouter` — deeplink mengalir lewat `navigationStream` dan
`main.dart` yang menavigasi. Infra tidak tahu apa pun tentang presentation.

### Verifikasi dependency rule (tiga grep — target NOL hasil)

```
$ grep -rEn "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/features/*/presentation
(nol hasil)

$ grep -rEn "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase" lib/features/*/domain lib/core
(nol hasil)

$ grep -rn "Impl(" lib/features/*/presentation | grep -v "providers/"
(nol hasil — instansiasi hanya terjadi di dalam Provider)

$ flutter analyze
No issues found!
```

File lama (`lib/data`, `lib/providers`, `lib/pages`, `lib/messaging`) sudah
saya hapus setelah semua pemindahan selesai. Hasil grep lengkap ada di
`docs/GREP_VERIFICATION.md`.

## Refactoring Challenge & Testing

Tiga tantangan refactor dari codelab, semuanya sudah saya terapkan:

1. **Pola sama untuk fitur kedua & ketiga** — auth dan announcements kini
   sama bersihnya dengan push: entity + interface repository + impl +
   use case + provider wiring. Tidak ada lagi fitur yang "kotor".
2. **`lib/core/format.dart`** — `maskToken`, `routeFromMessage`, dan
   `formatDate` menjadi fungsi murni yang bisa diuji tanpa widget
   (`test/auth_push_test.dart` membuktikan `routeFromMessage` tetap teruji
   setelah pindah rumah).
3. **Exception mentah → Failure** — `AuthRepositoryImpl` tidak lagi
   `throw Exception`; ia mengembalikan `ValidationFailure`/`AuthFailure`.
   `push_errors.dart` menerjemahkan `DioException` menjadi `Failure`.
   UI hanya menerima `failure.message` yang ramah.

### Test use case dengan repository palsu

Domain saya uji murni — tanpa SQLite, tanpa Dio, tanpa Firebase:

- `test/announcements/get_announcement_test.dart` — `FakeAnnouncementRepository`:
  sukses meneruskan data, failure tanpa melempar exception, validasi id kosong.
- `test/auth/sign_in_test.dart` — `FakeAuthRepository` + `FakeSessionRepository`:
  login sukses menyimpan sesi, login gagal TIDAK menyimpan sesi.
- `test/widget_test.dart` — smoke test aplikasi utuh dengan
  `ProviderScope(overrides: [...])` fake. Ini bukti paling nyata manfaat DI:
  dulu mustahil menjalankan app tanpa plugin Firebase, sekarang cukup override.

```
$ flutter test
All tests passed!  (11 test)
```

## Laporan akhir

### Struktur final

```
lib/
├── core/            failures.dart (sealed Failure) · format.dart (fungsi murni)
├── features/
│   ├── auth/            domain/{entities,repositories,usecases} · data/{models,repositories,token_store,api_client} · presentation/{providers,pages}
│   ├── announcements/   domain/{entities,repositories,usecases} · data/{models,repositories} · presentation/{providers,pages}
│   ├── push/            domain/repositories (interface+topics) · data (Firebase/Dio/Storage terkunci di sini) · presentation/providers
│   └── home/            presentation/pages (screen komposit)
├── main.dart        composition root (bootstrap Firebase + Router)
└── routes.dart      RoutePaths (pure Dart)
```

### Arah dependensi (yang saya gambar saat demo)

```
presentation ──► domain ◄── data
```

Domain tidak mengimpor apa pun dari Flutter/Dio/Firebase; presentation hanya
menyentuh data lewat satu titik: file provider.

### Stack teknologi

Flutter 3.47 / Dart 3.13 · flutter_riverpod ^3.4 (state + DI) · go_router ^18 ·
dio ^5.11 · flutter_secure_storage ^11 · firebase_core ^4 / firebase_messaging ^16 ·
flutter_local_notifications ^22 · flutter_lints ^6.

### Cara menjalankan

```bash
flutter pub get
flutter test              # 11 test domain murni + smoke test
flutter analyze           # bersih
flutter run -d <android>  # FCM butuh perangkat/emulator Android
```

### Screenshot before/after (perangkat CPH2269, Android 11)

#### Sebelum — bukti FCM minggu 6 (sebelum refactor)

| Notification "Test FCM" saat app tertutup | Foreground testing | Background testing | Recent tasks kosong (app terminated) | Terminated testing |
|---|---|---|---|---|
| ![before-1](screenshots/before/Screenshot_2026-10-04-23-40-13-21_40deb401b9ffe8e1df2f1cc5ba480b12.jpg) | ![before-2](screenshots/before/Screenshot_2026-10-05-02-49-51-02_a577b4e2495c416e6aaa7114589d0828.jpg) | ![before-3](screenshots/before/Screenshot_2026-10-05-03-11-02-05_92b64b2a7aa6eb3771ed6e18d0029815.jpg) | ![before-4](screenshots/before/Screenshot_2026-10-05-03-14-20-03_92b64b2a7aa6eb3771ed6e18d0029815.jpg) | ![before-5](screenshots/before/Screenshot_2026-10-05-03-14-32-78_92b64b2a7aa6eb3771ed6e18d0029815.jpg) |

#### Sesudah — hasil refactor, diambil via `flutter run` + `adb screencap`

| Home (auto-login dari secure storage) | Detail pengumuman dari repository | Route guard → login | Login demo berhasil | Deeplink terminated → `/pengumuman/1` |
|---|---|---|---|---|
| ![after-1](screenshots/after/after-01-home.png) | ![after-2](screenshots/after/after-02-announcement.png) | ![after-3](screenshots/after/after-03-login.png) | ![after-4](screenshots/after/after-04-home-after-login.png) | ![after-5](screenshots/after/after-05-deeplink-pengumuman.png) |

Bukti UI setelah refactor identik dengan sebelum refactor — padahal seluruh
rutenya sudah lewat repository/use case: detail pengumuman (judul + tanggal +
isi) diambil dari `AnnouncementRepository`, dan cold start terminated
`getInitialMessage` → `navigationStream` → `/pengumuman/1` tanpa `GoRouter`
masuk ke layer infra.

Uji manual lain yang tercatat di log runtime: toggle topic
(Unsubscribe/Subscribe bekerja lewat interface `PushRepository`), dan login
invalid menampilkan pesan `ValidationFailure` yang ramah — bukan exception mentah.

### Checklist definisi selesai (jobsheet)

- [x] Snapshot commit sebelum refactor.
- [x] 2+ fitur penuh terpisah domain/data/presentation — bukan sekadar pindah folder.
- [x] Tiga grep sterilitas NOL hasil (`docs/GREP_VERIFICATION.md`).
- [x] Interface di domain, implementasi di data, mapping hanya di model.
- [x] Widget tidak menginstansiasi repository; wiring terpusat di provider.
- [x] Aplikasi berjalan identik sebelum/sesudah (uji manual + screenshot di perangkat).
- [x] `flutter analyze` bersih, 11 test lulus (use case sukses + failure dengan repository palsu).
- [x] AI Challenge terdokumentasi (`docs/AI_CHALLENGE.md`): prompt, usulan-vs-keputusan, trade-off, refleksi.
