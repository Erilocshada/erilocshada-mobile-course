class RoutePaths {
  static const String home = '/';
  static const String login = '/login';
  static const String pengumumanDetail = '/pengumuman/:id';
}

/// Fungsi murni untuk mengekstrak rute dari payload data
String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route']?.toString() ?? RoutePaths.home;
  return route.startsWith('/') ? route : '/$route';
}
