import 'package:dio/dio.dart';

import '../../../core/failures.dart';

/// Mengubah DioException menjadi Failure ramah pengguna SEBELUM mencapai UI.
/// (Praktikum: exception mentah tidak boleh bocor ke presentation.)
Failure failureFromDio(DioException error) {
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return const NetworkFailure('Koneksi timeout, periksa jaringan Anda.');
  }
  if (error.type == DioExceptionType.connectionError) {
    return const NetworkFailure('Tidak ada koneksi internet.');
  }

  final statusCode = error.response?.statusCode;
  if (statusCode == 401) {
    return const AuthFailure('Sesi Anda telah berakhir, silakan login ulang.');
  } else if (statusCode == 403) {
    return const AuthFailure('Anda tidak memiliki akses ke fitur ini.');
  } else if (statusCode == 404) {
    return const NetworkFailure('Data tidak ditemukan.');
  } else if (statusCode == 405) {
    return const NetworkFailure('Endpoint belum aktif di server backend.');
  } else if (statusCode != null && statusCode >= 500) {
    return const NetworkFailure('Terjadi masalah pada server. Coba lagi nanti.');
  }

  return NetworkFailure(error.message ?? 'Terjadi kesalahan tidak terduga.');
}
