# Campus Notification App (`campus_notify`)

Aplikasi Flutter Campus Notification App menggunakan **Firebase Cloud Messaging (FCM)**, **Flutter Local Notifications**, **Flutter Secure Storage**, **GoRouter**, dan **Riverpod**.

---

## 📋 AI Verification Checklist & Temuan Verifikasi

Berikut adalah hasil verifikasi teknis dan pengujian terhadap implementasi `PushService` di [`lib/messaging/push_service.dart`](file:///d:/KULIAH/SMT-5/Pemmob/06-week-6-authentication-security-fcm/campus_notify/lib/messaging/push_service.dart):

### 1. Top-Level Background Handler (`@pragma('vm:entry-point')`)
- **Status:** ✅ **DITERIMA**
- **Verifikasi:** Fungsi `firebaseMessagingBackgroundHandler` dideklarasikan sebagai **fungsi top-level** (di luar class `PushService`) di file [`push_service.dart`](file:///d:/KULIAH/SMT-5/Pemmob/06-week-6-authentication-security-fcm/campus_notify/lib/messaging/push_service.dart#L23-L34) dan di-annotate dengan `@pragma('vm:entry-point')`.
- **Alasan Teknis:** Fungsi tidak berada dalam kelas, sehingga aman dari AOT tree-shaking dan dapat dieksekusi oleh Engine di Background Isolate saat aplikasi mati/background.

### 2. Pengiriman Token Baru pada `onTokenRefresh`
- **Status:** ✅ **DITERIMA**
- **Verifikasi:** Method `_initTokenAndListeners()` di `PushService` mendaftarkan listener `_messaging.onTokenRefresh.listen((newToken) async { await sendTokenToServer(newToken); });`.
- **Alasan Teknis:** Setiap kali FCM token ter-refresh, token baru secara otomatis disimpan di `FlutterSecureStorage` dan dikirim ke backend via HTTP `POST /devices`.

### 3. Local Notification Manual di Foreground
- **Status:** ✅ **DITERIMA**
- **Verifikasi:** Method `_setupForegroundMessageHandler()` menangani `FirebaseMessaging.onMessage.listen()` dan memicu `_showManualLocalNotification()`.
- **Alasan Teknis:** Secara default di Android & iOS, notifikasi FCM di foreground tidak memunculkan heads-up banner secara otomatis. Dengan memanggil `FlutterLocalNotificationsPlugin.show()`, notifikasi heads-up/banner dijamin muncul saat user sedang membuka aplikasi.

### 4. Tabel Pengujian Navigasi Notifikasi (3 State Aplikasi)
- **Status:** ✅ **TERUJI & DITERIMA**

| State Aplikasi | Trigger Notifikasi | Mekanisme Handler | Hasil Navigasi Rute (`data.route`) |
| :--- | :--- | :--- | :--- |
| **Foreground** (Aplikasi Terbuka) | FCM Push -> Banner Notifikasi Lokal Tampil -> User Tap Banner | Callback `onDidReceiveNotificationResponse` di `FlutterLocalNotificationsPlugin` memicu `_handleRouteNavigation(payload)`. | Navigasi berhasil ke `/pengumuman/:id` via `GoRouter`. |
| **Background** (Aplikasi Minimised) | FCM Push -> System Tray -> User Tap Notifikasi | Callback `FirebaseMessaging.onMessageOpenedApp.listen` menangkap `message.data['route']`. | Aplikasi terbuka dan navigasi ke `/pengumuman/:id` via `GoRouter`. |
| **Terminated** (Aplikasi Mati Total) | FCM Push -> System Tray -> User Tap Notifikasi | Method `FirebaseMessaging.instance.getInitialMessage()` membaca `message.data['route']` saat startup. | Aplikasi cold-boot dan langsung diarahkan ke `/pengumuman/:id`. |

### 5. Keamanan Token & Secret (No Hardcode & Masking Log)
- **Status:** ✅ **DITERIMA & DIPERBAIKI**
- **Verifikasi:**
  1. BaseURL dan endpoint diambil dari konfigurasi API/Dio.
  2. Token tidak di-hardcode. FCM token disimpan dengan aman di `FlutterSecureStorage`.
  3. Log token menggunakan fungsi helper `maskToken(token)` (contoh: `fcm_to...x92k`) untuk mencegah kebocoran identifier sensitif di sistem pengawasan/console log.

---

## 🎯 Keputusan Final AI Draft

- **Keputusan:** **DITERIMA (APPROVED)**
- **Alasan Teknis:** Seluruh 5 poin checklist utama telah terpenuhi dan diverifikasi dengan kode standar produksi. Penanganan konteks (*BuildContext-free architecture*) menjaga aplikasi dari *runtime exception* `Looking up a deactivated widget's ancestor is unsafe` atau error crash di background isolate.

---

## 🛠️ Error Umum & Solusinya

| Gejala | Penyebab umum | Solusi |
| :--- | :--- | :--- |
| **Token null di emulator** | Emulator tanpa Google Play Services | Pakai emulator dengan ikon Play Store atau perangkat fisik |
| **Banner tidak muncul saat foreground** | Mengandalkan banner otomatis sistem | Tampilkan manual via flutter_local_notifications di onMessage |
| **Klik notifikasi tidak navigasi (terminated)** | getInitialMessage tidak dipanggil saat startup | Panggil handleTerminated setelah router siap, teruskan data.route |
| **401 berulang meski sudah login** | Interceptor refresh tidak mengulang request / refresh ikut kedaluwarsa | Ulangi request sekali setelah refresh; bila gagal, clear() dan arahkan ke /login |
| **MissingPluginException secure storage / messaging** | Hot reload setelah tambah plugin | Hentikan penuh lalu flutter run ulang |
| **Notifikasi iOS tidak muncul** | Belum ada APNs key / capability push | Konfigurasi APNs di Firebase Console + aktifkan Push di Xcode |

---

## ✅ Checklist Verifikasi Mandiri

- [x] Token hanya di `flutter_secure_storage`, tidak di `SharedPreferences`/log/screenshot penuh.
- [x] 401 memicu refresh sekali lalu retry; refresh mati memaksa login ulang.
- [x] Ketiga app state teruji dengan tabel bukti; klik masuk ke rute yang benar.
- [x] Topik untuk broadcast, token untuk pesan personal.
