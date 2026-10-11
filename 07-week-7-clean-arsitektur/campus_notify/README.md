# Laporan Jobsheet #07 — Clean Architecture (campus_notify)

Saya merefactor project Minggu 6 saya, `campus_notify` (auth + FCM + pengumuman),
menjadi Clean Architecture feature-first. Laporan ini saya tulis bertahap
per praktikum sesuai codelab.

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
