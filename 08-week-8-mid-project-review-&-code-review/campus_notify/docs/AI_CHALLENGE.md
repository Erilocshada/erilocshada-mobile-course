# AI Challenge — Jobsheet #07 Clean Architecture

## 1. Prompt yang diberikan ke AI (sesuai jobsheet)

> Project Flutter saya: campus_notify (auth + FCM + daftar pengumuman).
> Kondisi kini: folder lib/{data, providers, pages, messaging},
> repository tercampur dengan implementasi, widget memanggil Dio langsung.
> Tugas:
> 1. Usulkan struktur feature-first Clean Architecture
>    (presentation/domain/data) untuk fitur auth + announcements.
> 2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
> 3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
>    dan kapan use case benar-benar dibutuhkan vs repository langsung.
> 4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
> Jelaskan trade-off setiap keputusan.

## 2. Output awal AI (ringkasan usulan)

Usulan AI: 3 fitur (`auth`, `announcements`, `push`) + `core/`, masing-masing
`domain/{entities,repositories,usecases}`, `data/{models,repositories}`,
`presentation/{providers,pages}`; `SignIn` dan `GetAnnouncement` jadi use case;
`PushService` dibalik jadi `PushRepository` (interface) + impl di data;
`failures.dart` sealed class di core; hasil mapping sukses/gagal pakai record
Dart, bukan `Either` dari fpdart.

## 3. Tabel usulan vs keputusan final + alasan

| Usulan AI | Keputusan final | Alasan / trade-off |
|---|---|---|
| Interface repository di folder `domain/`, impl di `data/` | **Diterima** | Inti dependency inversion; checklist AI Challenge mensyaratkan ini |
| Use case `SignIn` (authRepo + sessionRepo) | **Diterima** | Menggabungkan 2 repository = orkestrasi nyata, bukan CRUD satu baris |
| Use case per method CRUD announcement (`GetAnnouncement`, `GetAnnouncements`, `AddAnnouncement`, ...) | **Ditolak & disederhanakan** | Over-engineering: announcement hanya baca (tidak ada create dari UI). Hanya 1 use case `GetAnnouncement` karena ada aturan bisnis validasi id; `fetchAnnouncements` langsung repository→provider dengan alasan tertulis |
| Pakai `fpdart`/`dartz` (Either<Failure,T>) | **Ditolak** | Package tambahan tak perlu; record Dart bawaan (`({T?, Failure?})`) sudah eksplisit — jobsheet sendiri menyarankan record sebagai default |
| `PushService` dipecah 4 kelas kecil (permission, token, notification, routing) | **Ditolak (sebagian)** | Untuk scope praktikum, cukup DI-facing interface `PushRepository`; memecah file FCM 400 baris berisiko mengubah perilaku foreground/background/terminated yang sudah diuji minggu 6. Trade-off: SRP masih belum sempurna di `PushServiceImpl` — dicatat sebagai hutang teknis |
| `main.dart` meneruskan `GoRouter` ke `PushService` | **Ditolak & diubah** | Infra tidak boleh tahu presentation. Deep link sekarang mengalir lewat `navigationStream`; `main.dart` yang menavigasi. Perilaku sama (stream sudah dipakai listener), tapi arah panah dependensi benar |
| `ApiClient` dihapus karena dead code | **Ditolak** | Jobsheet: "memindahkan kode yang sudah ada", bukan menghapus fitur. Dipindah ke `features/auth/data/` + di-refactor agar bergantung abstraksi domain, siap untuk backend sungguhan |
| Semua file `pages/` dipindah per fitur | **Diterima** | Homepage bukan milik satu fitur → dibuat `features/home/presentation/` (screen komposit) |
| `maskToken`, `routeFromMessage`, `DateFormat` → `lib/core/format.dart` fungsi murni | **Diterima** | Refactoring Challenge jobsheet; kini teruji tanpa widget (auth_push_test menguji `routeFromMessage`) |

## 4. Wiring DI final (Riverpod, tanpa package DI tambahan)

```dart
// features/auth/presentation/providers/auth_providers.dart
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
final sessionRepositoryProvider =
    Provider<SessionRepository>((ref) =>
        SessionRepositoryImpl(ref.watch(tokenStoreProvider)));
final authRepositoryProvider =
    Provider<AuthRepository>((ref) => const AuthRepositoryImpl());
final signInProvider = Provider<SignIn>((ref) => SignIn(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionRepositoryProvider)));
final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
```

Bukti manfaat DI: `test/widget_test.dart` menjalankan aplikasi utuh dengan
`ProviderScope(overrides: ...)` fake — tanpa Firebase/secure storage sungguhan.

## 5. Verifikasi checklist AI (hasil grep — lihat GREP_VERIFICATION.md)

- [x] Interface di domain, implementasi di data (bukan satu folder).
- [x] Domain bebas import Flutter/Dio/SQLite/Firebase (grep nol hasil).
- [x] Tidak ada use case untuk tiap CRUD satu-baris (hanya 2 use case dengan alasan).
- [x] Entity bebas mapping — `toMap/fromMap/toJson` hanya di model.
- [x] Wiring DI terpusat di provider; widget tidak `new Repository()`.

## 6. Refleksi (jawaban pertanyaan jobsheet)

1. **Kenapa interface repository di domain?** Karena domain adalah inti yang
   stabil; kalau interface hidup di data, presentation/widget ikut bergantung
   pada detail infra (Arahan Dependensi Inversion Terbalik) dan penggantian
   mock→Firebase memaksa edit UI/notifier.
2. **Kapan use case dibutuhkan?** Saat orkestrasi >1 repository atau ada aturan
   bisnis (validasi, sorting, sync) — mis. `SignIn` (auth+session) dan
   `GetAnnouncement` (validasi id). CRUD satu baris cukup repository→notifier.
3. **Biaya over-engineering?** Setiap use case = 1 kelas + 1 provider + boilerplate
   record; untuk CRUD sederhana tim kecil ini menambah taksi tanpa nilai dan
   memperlah paham kode. Sepadan bila tim besar/logika sering berubah.
4. **Bagian yang saya tolak dari AI:** use case per method CRUD, paket `fpdart`,
   dan pemecahan 4 kelas PushService (alasan di tabel §3).
