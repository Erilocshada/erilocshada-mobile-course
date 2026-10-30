# Review Checklist & Kesiapan Tengah Semester — Jobsheet #08

> Mata kuliah: Pemrograman Mobile · Minggu 8 · Project: `campus_notify`
> Tanggal audit: 27 Oktober 2026

## 1. Audit riwayat Git saya (Praktikum 1.1)

Perintah yang dijalankan di repository portfolio:

```
git log --oneline -15
git branch -a
git status
```

Temuan masalah:

| # | Masalah | Bukti di riwayat |
|---|---|---|
| 1 | Semua commit masuk langsung ke `main`, tidak pernah lewat PR | `git branch -a` hanya menunjukkan `main` sebelum minggu 8 |
| 2 | Pesan commit tanpa format konvensional | `Laporan Praktikum`, `Refactoring Challenge`, `Terminate Testing`, `Background`, `Improve README.md with detailed notification features` |
| 3 | Commit ganda/duplikat tanpa makna jelas | `44d8020 Praktikum Jobsheet 6` dan `f34db7e Praktikum Jobsheet 6` berurutan |
| 4 | Branch kerja tidak pernah dibuat | tidak ada `feature/*` maupun `fix/*` pada `git branch -a` |
| 5 | Folder kerja minggu 8 lama tidak di-commit (untracked) | `git status`: `?? 08-week-8-mid-project-review-&-code-review/` |
| 6 | Folder materi (`Modul/`) bercampur dengan aset portfolio | kini dikecualikan lewat `.gitignore` (commit `6b4dfe7`) |

## 2. Tabel sebelum/sesudah commit (Praktikum 1.3 — simulasi rewrite)

| Sebelum (lama) | Sesudah (konvensional) | Alasan |
|---|---|---|
| `Laporan Praktikum` | `docs(week7): laporan praktikum clean architecture + checklist grep` | Jelas APA yang berubah (dokumentasi), DI MANA (laporan minggu 7), dan cukup spesifik untuk dipilih saat `git revert` |
| `fix bug` / `Terminate Testing` | `test(push): verifikasi perilaku notifikasi saat app terminated` | Pesan lama tidak menyebut jenis perubahan dan area-nya; commit ini sebenarnya test, bukan fix — tipenya harus `test` |
| `44d8020 Praktikum Jobsheet 6` (duplikat) | `feat(push): integrasi firebase messaging — tahap 1 setup & tahap 2 handler` | Dua commit identik melanggar "satu commit = satu perubahan logis"; idealnya dipecah per tanggung jawab dengan scope yang jelas |

## 3. Yang sudah dilakukan minggu ini (Git Flow baru)

- [x] `develop` dibuat sekali dari `main` (commit snapshot `c118ad6`), bukan dikerjakan di `main`.
- [x] Branch kerja `feat/week8-review-discipline` dibuat dari `develop`; tiap commit satu tanggung jawab (`style` / `fix+test` / `chore` / `docs` / `ci`).
- [x] `git add` diseleksi per kelompok file (analog `git add -p`) agar commit format murni terpisah dari commit perubahan perilaku — dibuktikan dengan pemisahan diff di `5650d72` vs `f6d74c5`.

## 4. Static analysis & mesin (Praktikum 3.1)

Hasil per 27 Oktober 2026 di `campus_notify`:

| Pemeriksaan | Perintah | Hasil |
|---|---|---|
| Analyzer | `flutter analyze` | `No issues found!` |
| Format | `dart format --output=none --set-exit-if-changed .` | bersih (0 changed) — setelah `style(week8)` commit |
| Test | `flutter test` | **12/12 lulus** (sebelumnya 10 lulus, 1 gagal: smoke test menyentuh Firebase; +1 test baru guard null `SignIn`) |

Catatan alat: path folder minggu 8 mengandung karakter `&` yang membuat build *native assets hook* Flutter crash di Windows (`FileSystemException` saat `flutter test` dijalankan langsung dari folder tersebut). Workflow lokal: `subst W:` (drive virtual) → `flutter test` hijau. CI Linux (GitHub Actions) tidak terpengaruh.

## 5. Penilaian kesiapan tengah semester

| Aspek | Status | Catatan |
|---|---|---|
| Struktur feature-first terbukti (3 grep sterilitas minggu 7) | ✅ | lihat `docs/GREP_VERIFICATION.md` |
| `flutter analyze` bersih | ✅ | §4 |
| `flutter test` hijau | ✅ | 12/12, termasuk bukti merah→hijau temuan AI |
| PR kecil + commit jelas | ✅ | branch `feat/week8-review-discipline`, 5 commit kecil tipe-scope |
| README + screenshot + cara menjalankan | ✅ | `README.md` minggu 8 + `screenshots/week8/` |
| Komentar review ditindaklanjuti | ⏳ | menunggu peer review pasangan di GitHub (issue + PR tercatat di README) |
| CI menolak PR kotor | ✅ | `.github/workflows/ci.yml` menolak analyze/format/test gagal |

**Kesimpulan pribadi:** fondasi sudah bisa dipercaya untuk paruh kedua; hutang teknis yang saya akui dan catat: (1) `PushServiceImpl` masih ~430 baris (SRP belum sempurna, sengaja tidak dipecah karena risiko mengubah perilaku foreground/background/terminated yang sudah diuji minggu 6), (2) `ApiClient` auto-refresh belum diuji end-to-end karena backend masih mock.
