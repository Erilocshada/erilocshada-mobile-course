# Academic Overview Dashboard

Flutter dashboard responsif untuk ringkasan akademik mahasiswa.

## Struktur

- `DashboardApp` mengelola light theme, dark theme, dan toggle tema.
- `DashboardPage` mengatur header profil dan layout responsif.
- `InfoCard` adalah widget reusable untuk informasi akademik.
- `kWideBreakpoint` menjadi satu-satunya breakpoint lebar (`700.0`).

## Perilaku Responsif

- Lebar kurang dari `700.0`: kartu ditampilkan satu kolom.
- Lebar minimal `700.0`: kartu ditampilkan dua kolom.
- Kartu menggunakan warna dari `ColorScheme` dan teks dari `TextTheme` agar tetap terbaca pada kedua tema.

## Aksesibilitas

- Profil, kartu informasi, dan toggle tema memiliki label `Semantics`.
- Nilai kartu tetap dapat dibaca screen reader meskipun teks visual perlu dipadatkan pada layar sempit.

## Menjalankan

```bash
flutter pub get
flutter run
```

## Testing

```bash
flutter analyze
flutter test
```

Widget test di `test/widget_test.dart` memverifikasi ukuran kartu pada layar sempit `400x800` dan layar lebar `1200x800`.

## Screenshot

Screenshot hasil runtime dapat disimpan di folder `Screenshots/` pada folder tugas Week 2.
