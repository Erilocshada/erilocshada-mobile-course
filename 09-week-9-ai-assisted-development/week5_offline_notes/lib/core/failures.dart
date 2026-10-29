/// Failure domain murni Dart — tanpa import Flutter/Dio/SQLite/SharedPreferences.
/// Semua exception mentah dari data layer dikonversi menjadi Failure sebelum
/// pernah mencapai presentation (pola yang sama dengan minggu 7/8).
sealed class Failure {
  const Failure(this.message);

  final String message;
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}
