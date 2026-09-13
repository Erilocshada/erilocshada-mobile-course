# ToDo Navigation dan State Management

Aplikasi ToDo untuk tugas minggu ke-3 Mobile Development. Aplikasi ini mendemonstrasikan navigasi ant halaman dengan GoRouter dan pengelolaan state asinkron menggunakan Riverpod `AsyncNotifier`.

## Tujuan

- Menerapkan navigasi declarative menggunakan GoRouter.
- Mengelola state daftar tugas dengan Riverpod dan `ConsumerWidget`.
- Memahami alur `AsyncValue`: loading, error, dan success.
- Membuat test widget untuk perilaku utama aplikasi.

## Fitur Utama

- Halaman Daftar Tugas dengan tugas yang belum selesai.
- Toggle status tugas selesai/belum selesai.
- Halaman Detail dan Statistik yang memakai state provider yang sama.
- Simulasi pemuatan data asinkron.
- Tombol simulasi error dan tombol coba lagi.
- Indikator loading, pesan error, dan tampilan data sukses.
- Navigasi bottom navigation antara Tugas dan Statistik.

## Stack Teknologi

- Flutter dan Dart.
- `flutter_riverpod` untuk state management.
- `go_router` untuk routing.
- `flutter_test` untuk widget test.

## Struktur Proyek

```text
lib/
  main.dart
  pages/
    stats_page.dart
    todo_page.dart
  providers/
    todo_provider.dart
  widgets/
    todo_tile.dart
test/
  widget_test.dart
screenshots/
README.md
```

## Cara Menjalankan

Prasyarat: Flutter SDK terpasang dan perangkat/emulator tersedia.

```bash
flutter pub get
flutter run
```

Validasi kode dan test:

```bash
flutter analyze
flutter test
```

Untuk menguji error state, buka halaman Tugas lalu tekan ikon cloud off. Untuk kembali ke success state, tekan Coba lagi.

## Hasil yang Dicapai

- Dua halaman aktif dan dapat dinavigasikan dengan GoRouter.
- State daftar tugas dibagikan antara halaman Tugas dan Statistik melalui provider Riverpod.
- State loading muncul saat data disimulasikan sedang dimuat.
- State error muncul melalui simulasi kegagalan dan dapat dipulihkan dengan retry.
- State success menampilkan daftar tugas dan ringkasan statistik.
- Widget test mencakup pemuatan awal, navigasi, dan error state.

## AI Challenge

### Prompt yang digunakan

> Buat rancangan aplikasi ToDo Flutter untuk tugas minggu ke-3. Gunakan GoRouter untuk minimal dua halaman, Riverpod `AsyncNotifier` dan `ConsumerWidget` untuk state, serta tampilkan state loading, error, dan success. Sertakan widget test, struktur folder portfolio, dan dokumentasi keputusan teknis dalam bahasa Indonesia. Gunakan pendekatan yang sederhana, mudah diuji, dan tidak menambahkan dependensi yang tidak diperlukan.

### Hasil awal AI

AI menghasilkan fondasi `MaterialApp.router`, `ShellRoute`, provider daftar tugas berbasis `AsyncNotifier`, halaman daftar, halaman statistik, dan satu widget test. Fondasi tersebut sudah sesuai arah tugas, tetapi dokumentasi bawaan proyek masih berupa template dan alur error belum mudah dipicu dari UI.

### Perbaikan yang dilakukan

- Memindahkan hasil kerja ke folder portfolio khusus `03-week-3-navigation-state-management/`.
- Mengubah data awal menjadi contoh tugas proyek agar lebih relevan.
- Menambahkan tombol simulasi error, retry, dan refresh agar tiga kondisi `AsyncValue` bisa diamati langsung.
- Menambahkan tampilan statistik yang membaca provider utama yang sama.
- Menambahkan test untuk loading, success, navigasi, dan error.
- Mengganti README template dengan dokumentasi tujuan, fitur, stack, cara menjalankan, hasil, dan proses AI Challenge.

### Alasan keputusan teknis

- `AsyncNotifier` dipilih karena state memiliki proses loading dan error, bukan hanya nilai sinkron.
- `ConsumerWidget` dipakai pada halaman agar pembacaan provider eksplisit melalui `WidgetRef`.
- `ShellRoute` dipakai supaya bottom navigation tetap konsisten saat route berubah.
- Simulasi error dibuat sebagai parameter pada `refresh`, sehingga perilaku jaringan dapat diuji tanpa backend sungguhan.
- Tidak menambahkan database atau package lain karena ruang lingkup tugas berfokus pada navigasi dan state management.
