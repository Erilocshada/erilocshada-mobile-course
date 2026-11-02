import '../routes.dart';

/// Fungsi murni (pure functions) lintas fitur — bisa diuji tanpa widget.
/// Dipindah dari messaging/push_service.dart dan routes.dart (Praktikum 1).

/// Menyamarkan token agar tidak tercetak penuh di log.
String maskToken(String token) {
  if (token.length <= 12) return '***';
  return '${token.substring(0, 6)}...${token.substring(token.length - 6)}';
}

/// Mengekstrak rute navigasi dari payload pesan FCM.
String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route']?.toString() ?? RoutePaths.home;
  return route.startsWith('/') ? route : '/$route';
}

/// Format tanggal tampilan (dd/MM/yyyy) tanpa package intl.
String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
