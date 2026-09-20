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
      <img src="Screenshoot/Uji3.png" width="400">
    </td>
  </tr>
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

