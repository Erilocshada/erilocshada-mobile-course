/// Konstanta topic bisnis — domain yang mendefinisikan, data yang mengeksekusi.
abstract class PushTopics {
  static const String kampus = 'pengumuman-kampus';
}

/// Kontrak domain untuk notifikasi push.
/// Presentation bergantung pada abstraksi ini, bukan pada PushService/Firebase.
abstract class PushRepository {
  /// Inisialisasi izin, channel, token, handler, dan topic default.
  Future<void> start();

  /// Stream rute deeplink dari notifikasi (tanpa BuildContext).
  Stream<String> get navigationStream;

  Future<void> subscribeTopic(String topic);

  Future<void> unsubscribeTopic(String topic);

  Future<String?> deviceToken();

  void dispose();
}
