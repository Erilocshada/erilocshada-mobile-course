import 'package:dio/dio.dart';

class ApiErrors {
  static String getFriendlyErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Koneksi timeout, periksa jaringan Anda.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Tidak ada koneksi internet.';
      }
      
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return 'Sesi Anda telah berakhir, silakan login ulang.';
      } else if (statusCode == 403) {
        return 'Anda tidak memiliki akses ke fitur ini.';
      } else if (statusCode == 404) {
        return 'Data tidak ditemukan.';
      } else if (statusCode == 405) {
        return 'Endpoint belum aktif di server backend.';
      } else if (statusCode != null && statusCode >= 500) {
        return 'Terjadi masalah pada server. Coba lagi nanti.';
      }
      return error.message ?? 'Terjadi kesalahan tidak terduga.';
    }
    return error.toString();
  }
}
