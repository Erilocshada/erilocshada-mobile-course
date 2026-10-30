/// Failure domain murni Dart — tanpa import Flutter/Dio/SQLite/Firebase.
/// Semua exception mentah dikonversi menjadi Failure di data layer
/// sebelum pernah mencapai presentation.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}
