# Verifikasi Sterilitas — 2026-10-11

## Grep 1: presentation steril dari data mentah (target: NOL hasil)

```
$ grep -rEn "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/features/announcements/presentation lib/features/auth/presentation lib/features/home/presentation lib/features/push/presentation
(nol hasil)
```

## Grep 2: domain & core steril dari framework/package (target: NOL hasil)

```
$ grep -rEn "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase" lib/features/*/domain lib/core
(nol hasil)
```

## Grep 3: instansiasi hanya di provider (widget tidak new Repository())

```
$ grep -rn "Impl(" lib/features/*/presentation | grep -v providers/  # harus kosong
(nol hasil — semua wiring di file providers/)
```

## flutter analyze

```
$ flutter analyze
No issues found!
```

## flutter test

```
$ flutter test
All tests passed! (11 test)
```
