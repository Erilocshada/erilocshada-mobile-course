import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../data/api_errors.dart';
import '../routes.dart';

/// Helper untuk menyamarkan Token agar tidak tercetak penuh di Log (Keamanan)
String maskToken(String token) {
  if (token.length <= 12) return '***';
  return '${token.substring(0, 6)}...${token.substring(token.length - 6)}';
}

/// ============================================================================
/// 1. TOP-LEVEL BACKGROUND HANDLER
/// ============================================================================
/// ⛔ [TANPA BUILDCONTEXT]
/// Handler ini DIWAJIBKAN bertipe top-level (di luar class apa pun) dan
/// di-annotate dengan `@pragma('vm:entry-point')` agar tidak di-strip oleh AOT compiler.
///
/// PERINGATAN KONTREKS / BUILDCONTEXT:
/// Fungsi ini berjalan di Isolate terpisah (Background Isolate) ketika aplikasi
/// dalam kondisi background atau terminated (mati).
/// TIDAK ADA UI dan TIDAK BISA mengakses BuildContext, InheritedWidget,
/// ataupun ProviderScope UI di sini!
/// ============================================================================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Wajib melakukan initializeApp jika perlu mengakses Firebase service di background isolate.
  await Firebase.initializeApp();

  debugPrint('*** [FCM Background Handler] Message ID: ${message.messageId} ***');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Data: ${message.data}');
}

/// ============================================================================
/// 2. PUSH SERVICE CLASS
/// ============================================================================
class PushService {
  PushService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    FlutterSecureStorage? secureStorage,
    Dio? dio,
    String? baseUrl,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? 'https://example.com/api',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            ) {
    // Interceptor bawaan untuk menangani URL Dummy (example.com) secara Mock
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Jika masih menggunakan URL Dummy (example.com), simulasikan HTTP 200 OK
          if (options.baseUrl.contains('example.com') &&
              options.path.contains('/devices')) {
            debugPrint(
              'ℹ️ [MOCK SERVER INTERCEPTOR] POST /devices disimulasikan SUKSES (HTTP 200 OK) untuk pengujian lokal.',
            );
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'message': 'Device token registered (Mock Mode)',
                },
              ),
            );
          }
          return handler.next(options);
        },
      ),
    );
  }

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FlutterSecureStorage _secureStorage;
  final Dio _dio;

  /// Channel ID untuk Android High Importance Notifications
  static const String _androidChannelId = 'campus_notify_channel';
  static const String _androidChannelName = 'Campus Notifications';
  static const String _androidChannelDesc =
      'Channel ini digunakan untuk notifikasi penting kampus.';

  /// Storage Key
  static const String _tokenStorageKey = 'fcm_device_token';

  /// Topic Pengumuman Kampus
  static const String defaultTopic = 'pengumuman-kampus';

  /// Controller stream rute navigasi untuk mentransfer deeplink tanpa BuildContext langsung
  final StreamController<String> _navigationStreamController =
      StreamController<String>.broadcast();

  Stream<String> get navigationStream => _navigationStreamController.stream;

  /// Reference ke GoRouter (opsional, jika di-inject saat init)
  GoRouter? _router;

  /// ==========================================================================
  /// INITIALIZATION METHOD
  /// ==========================================================================
  Future<void> initialize({GoRouter? router}) async {
    _router = router;

    // 1. Minta Izin Notifikasi (Platform Specific Permission)
    await requestPermission();

    // 2. Setup Local Notification & Channel (Android & iOS Configuration)
    await _setupLocalNotifications();

    // 3. Ambil FCM Token & Kirim ke Server POST /devices + Dengarkan Refresh
    await _initTokenAndListeners();

    // 4. Setup FCM Foreground Handler (onMessage)
    _setupForegroundMessageHandler();

    // 5. Setup FCM Background & Terminated Notification Click Handler (onMessageOpenedApp & getInitialMessage)
    await _setupNotificationClickHandlers();

    // 6. Otomatis Subscribe ke Topic Pengumuman Kampus
    await subscribeTopic(defaultTopic);
  }

  /// ==========================================================================
  /// A. REQUEST PERMISSION
  /// ==========================================================================
  /// 📱 [ANDROID 13+ (API 33+)]: Menggunakan runtime permission POST_NOTIFICATIONS.
  ///    `requestPermission()` dari FirebaseMessaging otomatis memicu popup izin di Android 13+.
  /// 🍎 [iOS]: Meminta izin Alert, Badge, Sound, dan AuthorizationStatus.
  /// ==========================================================================
  Future<bool> requestPermission() async {
    // 🍎 [iOS] & 📱 [ANDROID 13+] Permission Request
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Authorization Status: ${settings.authorizationStatus}');

    // 📱 [ANDROID 13+] Minta izin eksplisit melalui flutter_local_notifications jika di Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImplementation?.requestNotificationsPermission();
      debugPrint('Android 13+ Local Notification Permission Granted: $granted');
    }

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// ==========================================================================
  /// B. SETUP LOCAL NOTIFICATIONS (Android Channel & iOS Presentation)
  /// ==========================================================================
  Future<void> _setupLocalNotifications() async {
    // 📱 [ANDROID 13+]: Android membutuhkan Notification Channel agar notifikasi muncul dengan High Importance.
    const androidChannel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDesc,
      importance: Importance.max,
      playSound: true,
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(androidChannel);

    // Initialization Settings per Platform
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 🍎 [iOS]: Configuration untuk darwin notification settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // ⛔ [TANPA BUILDCONTEXT]
    // Callback `onDidReceiveNotificationResponse` dipanggil saat user menekan notifikasi lokal.
    // Callback ini TIDAK memberikan BuildContext. Kita meneruskan payload rute ke _handleRouteNavigation.
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint('Local Notification Tapped with Payload: $payload');
          _handleRouteNavigation(payload);
        }
      },
    );

    // 🍎 [iOS]: Opsional setting agar notifikasi FCM foreground tetap tampil sebagai Banner/Alert bawaan iOS jika tidak di-handle manual.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// ==========================================================================
  /// C. GET TOKEN & ON TOKEN REFRESH (POST /devices & Secure Storage)
  /// ==========================================================================
  /// ⛔ [TANPA BUILDCONTEXT]
  /// Pengambilan token dan listener token refresh bersifat asynchronous/background.
  /// Tidak bergantung pada widget tree maupun BuildContext.
  /// ==========================================================================
  Future<void> _initTokenAndListeners() async {
    try {
      // 🍎 [iOS]: Pada simulator/device iOS, pastikan APNs token tersedia sebelum meminta FCM token
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _messaging.getAPNSToken();
        debugPrint('APNs Token (masked): ${apnsToken != null ? maskToken(apnsToken) : "null"}');
      }

      final token = await getToken();
      if (token != null) {
        await sendTokenToServer(token);
      }
    } catch (e) {
      debugPrint('Gagal mengambil FCM Token saat inisialisasi: $e');
    }

    // Dengarkan perubahan token (onTokenRefresh)
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM Token Ter-refresh (masked): ${maskToken(newToken)}');
      await sendTokenToServer(newToken);
    });
  }

  /// Mendapatkan FCM Token terbaru dari device
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Mengirim FCM Token ke Server API (POST /devices) & Simpan di Secure Storage
  Future<void> sendTokenToServer(String token) async {
    try {
      // 1. Simpan di FlutterSecureStorage
      await _secureStorage.write(key: _tokenStorageKey, value: token);
      debugPrint('FCM Token tersimpan di Secure Storage.');

      // 2. Kirim POST ke endpoint /devices
      final response = await _dio.post(
        '/devices',
        data: {
          'token': token,
          'device_type': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        },
      );

      debugPrint('Success POST /devices: ${response.statusCode} - ${response.data}');
    } on DioException catch (e) {
      final friendlyMessage = ApiErrors.getFriendlyErrorMessage(e);
      if (e.response?.statusCode == 405 || e.response?.statusCode == 404) {
        debugPrint(
          '⚠️ [BACKEND NOTICE] $friendlyMessage '
          'Token FCM tetap tersimpan aman di Secure Storage.',
        );
      } else {
        debugPrint('Gagal mengirim FCM Token ke POST /devices: $friendlyMessage');
      }
    } catch (e) {
      debugPrint('Gagal mengirim FCM Token ke POST /devices: $e');
    }
  }

  /// Mendapatkan token yang tersimpan di Secure Storage
  Future<String?> getSavedToken() async {
    return await _secureStorage.read(key: _tokenStorageKey);
  }

  /// ==========================================================================
  /// D. ON MESSAGE (Foreground Message Listener)
  /// ==========================================================================
  /// Menangani pesan notifikasi yang masuk saat aplikasi sedang DIBUKA (Foreground).
  /// Kita menampilkan notifikasi lokal secara manual via FlutterLocalNotificationsPlugin.
  /// ==========================================================================
  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('*** [FCM Foreground Message Received] ***');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      _showManualLocalNotification(message);
    });
  }

  /// Menampilkan Notifikasi Lokal secara Manual
  void _showManualLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'Pengumuman Kampus';
    final body =
        notification?.body ?? data['body'] ?? data['message'] ?? 'Ada pesan baru.';
    final routePayload = routeFromMessage(data);

    final notificationId = message.messageId?.hashCode ??
        DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 📱 [ANDROID 13+] Configuration Detail
    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      showWhen: true,
    );

    // 🍎 [iOS] Configuration Detail
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    _localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: routePayload,
    );
  }

  /// ==========================================================================
  /// E. ON MESSAGE OPENED APP & GET INITIAL MESSAGE (Routing Data)
  /// ==========================================================================
  /// ⛔ [TANPA BUILDCONTEXT]
  /// Penanganan klik notifikasi terjadi saat callback dieksekusi oleh OS.
  /// Karena penanganan ini bisa terjadi sebelum UI/Widget dirender lengkap,
  /// kita TIDAK melewatkan BuildContext secara langsung ke method ini.
  /// Sebagai gantinya, kita menggunakan instance `GoRouter` atau `StreamController`.
  /// ==========================================================================
  Future<void> _setupNotificationClickHandlers() async {
    // 1. App di Background lalu dibuka user via klik notifikasi
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('*** [FCM Message Opened App (Background Click)] ***');
      final route = routeFromMessage(message.data);
      if (route != RoutePaths.home || message.data.containsKey('route')) {
        _handleRouteNavigation(route);
      }
    });

    // 2. App dari Terminated (Mati) dibuka user via klik notifikasi
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('*** [FCM Initial Message (Terminated App Click)] ***');
      final route = routeFromMessage(initialMessage.data);
      if (route != RoutePaths.home || initialMessage.data.containsKey('route')) {
        _handleRouteNavigation(route);
      }
    }
  }

  /// Navigasi ke rute tanpa membutuhkan BuildContext langsung
  void _handleRouteNavigation(String route) {
    debugPrint('Navigating to route: $route');

    // Opsi A: Jika GoRouter instance sudah didaftarkan ke PushService
    if (_router != null) {
      _router!.go(route);
    }

    // Opsi B: Kirim ke Stream agar Listener di UI / App level bisa merespons
    _navigationStreamController.add(route);
  }

  /// ==========================================================================
  /// F. SUBSCRIBE & UNSUBSCRIBE TOPIC ('pengumuman-kampus')
  /// ==========================================================================
  Future<void> subscribeTopic([String topic = defaultTopic]) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Berhasil Subscribe ke Topic: $topic');
    } catch (e) {
      debugPrint('Gagal Subscribe ke Topic $topic: $e');
    }
  }

  Future<void> unsubscribeTopic([String topic = defaultTopic]) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Berhasil Unsubscribe dari Topic: $topic');
    } catch (e) {
      debugPrint('Gagal Unsubscribe dari Topic $topic: $e');
    }
  }

  void dispose() {
    _navigationStreamController.close();
  }
}
