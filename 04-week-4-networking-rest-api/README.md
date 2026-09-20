# Praktikum 1
1. Model data dengan fromJson aman null
2. Konfigurasi Dio terpusat
3. Repository sebagai pintu data


Foto:

<table>
  <tr>
    <td>
      <img src="Screenshoot/Praktikum1.png" width="400">
    </td>
</table>

# Praktikum 2
1. Provider AsyncNotifier + pesan error ramah pengguna
2. UI: loading, error, empty, success
3. Entry point dengan ProviderScope


Foto :

<table>
    <td>
      <img src="Screenshoot/Praktikum2.png" width="400">
    </td>
  </tr>
</table>

### Uji skenario error
#### 1. Jalankan aplikasi dengan internet normal, amati loading lalu daftar 100 posts.

   Foto:

   <table>
    <td>
      <img src="Screenshoot/Praktikum2.png" width="400">
    </td>
  </tr>
</table>

#### 2. Matikan internet (mode pesawat), tekan refresh, amati pesan ramah + tombol Coba lagi. Nyalakan kembali internet, tekan Coba lagi.

Foto :

<table>
    <td>
      <img src="Screenshoot/Uji2.png" width="400">
    </td>
  </tr>
</table>

#### 3. Sementara ubah baseUrl menjadi URL salah, amati pesan error koneksi. Kembalikan setelah uji.
<table>
    <td>
      <img src="Screenshoot/Uji2.png" width="400">
    </td>
  </tr>
    <td>
      <img src="Screenshoot/Uji3.png" width="400">
    </td>
  </tr>
  <tr>
    <td>
      <img src="Screenshoot/Uji3.1.png" width="400">
    </td>
  </tr>
</table>

# Praktikum 3
1. Repository paginated
2. Notifier dengan state halaman
3. UI infinite scroll

# AI Chalenge
#### Checklist verifikasi AI
1.  UI tidak memanggil Dio langsung

UI tidak melakukan request API sendiri. Semua request dipindahkan ke repository dan provider.

2. fromJson aman null

Benar, tidak memakai cast langsung yang bisa crash. Semua field aman dengan fallback default.

3. Semua DioExceptionType dipetakan ke pesan user

Timeout, connection error, badResponse dipetakan. Untuk badResponse sudah ada mapping:

- 404
- 500
- 401/403
- default error

4. baseUrl/timeout terpusat

Benar, semua config Dio ada di api_client.dart, bukan tersebar.
5.  Test edge case minimal sudah ada

Sudah ada 1 unit test khusus untuk field yang hilang.

6. flutter analyze + flutter test -> Sudah dijalankan dan hasilnya berhasil.

# Refleksi
1. UI tidak disarankan untuk berinteraksi langsung dengan Dio karena setiap komponen dalam aplikasi sebaiknya memiliki tanggung jawab yang terpisah. UI berfokus pada proses menampilkan informasi kepada pengguna, sedangkan proses pengambilan data dari API ditangani oleh Repository. Apabila UI secara langsung menggunakan Dio, struktur kode akan menjadi lebih sulit untuk dipelihara maupun dilakukan pengujian. Selain itu, ketika library Dio perlu diganti, misalnya menggunakan http, perubahan kode dapat dilakukan hanya pada bagian Repository yang menangani komunikasi dengan API tanpa perlu memodifikasi banyak bagian pada UI.


2. Pagination pada sisi client lebih sesuai diterapkan ketika jumlah data yang dikelola masih relatif sedikit. Sebagai contoh, daftar kontak dengan jumlah sekitar 100 hingga 500 data masih memungkinkan untuk dimuat secara keseluruhan tanpa memberikan beban yang terlalu besar terhadap aplikasi.


Sementara itu, pagination pada sisi server lebih tepat digunakan untuk menangani data dalam jumlah besar, seperti data transaksi, artikel berita, maupun timeline media sosial. Data tidak perlu dimuat sekaligus, tetapi dapat dikirim secara bertahap dengan memanfaatkan parameter seperti `_page` dan `_limit`. Dengan cara tersebut, penggunaan memori perangkat dan kuota internet dapat dikurangi sehingga proses pengambilan data menjadi lebih efisien.
3. Ketika terjadi kesalahan pada Repository hingga menghasilkan exception, Riverpod dapat menangani kondisi tersebut melalui `AsyncNotifier` maupun `FutureProvider`. Dalam keadaan ini, status data akan berubah menjadi `AsyncError`, sehingga UI hanya perlu membaca status tersebut untuk menentukan apakah pesan kesalahan perlu ditampilkan kepada pengguna. Meskipun demikian, penggunaan `try/catch` tetap diperlukan pada kondisi tertentu ketika error membutuhkan penanganan yang lebih spesifik. Contohnya adalah ketika pengguna melakukan proses login, mengirimkan data melalui tombol, atau ketika aplikasi perlu memberikan notifikasi berupa `Snackbar` maupun `Dialog` sebagai informasi bahwa telah terjadi kesalahan.

4. Perbaikan dilakukan pada beberapa bagian, seperti susunan folder, penggunaan import, serta mekanisme penghubungan antara Provider dan Repository. Langkah tersebut diperlukan karena kode yang dihasilkan oleh AI belum tentu sesuai dengan struktur proyek yang telah dibuat sebelumnya. Pada proses unit testing, dapat ditemukan pula beberapa masalah, seperti import yang belum tersedia atau implementasi kode yang tidak sesuai dengan fungsi pada proyek. Oleh karena itu, kode perlu disesuaikan agar dapat berjalan sebagaimana mestinya sekaligus tetap mengikuti struktur dan arsitektur aplikasi yang telah diterapkan.
