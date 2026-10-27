import 'package:dio/dio.dart';

import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/session_repository.dart';

/// Dio terpusat dengan auto-refresh token. Hanya boleh dipakai data layer
/// (repository impl), TIDAK boleh diimpor presentation.
/// Belum dipakai fitur mock saat ini — disiapkan untuk backend sungguhan.
class ApiClient {
  ApiClient({
    required AuthRepository authRepo,
    required SessionRepository sessionRepo,
  })  : _authRepository = authRepo,
        _sessionRepository = sessionRepo {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.com/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken =
          await _sessionRepository.accessToken();

          if (accessToken != null &&
              accessToken.isNotEmpty) {
            options.headers['Authorization'] =
            'Bearer $accessToken';
          }

          handler.next(options);
        },

        onError: (error, handler) async {
          if (error.response?.statusCode != 401) {
            handler.next(error);
            return;
          }

          try {
            final refreshToken =
            await _sessionRepository.refreshToken();

            if (refreshToken == null ||
                refreshToken.isEmpty) {
              await _sessionRepository.clear();

              handler.next(error);
              return;
            }

            final result =
            await _authRepository.refresh(
              refreshToken,
            );

            final newAccessToken = result.accessToken;
            if (newAccessToken == null) {
              await _sessionRepository.clear();
              handler.next(error);
              return;
            }

            await _sessionRepository.save(
              accessToken: newAccessToken,
              refreshToken: refreshToken,
            );

            final requestOptions =
                error.requestOptions;

            requestOptions.headers['Authorization'] =
            'Bearer $newAccessToken';

            final response = await _dio.fetch(
              requestOptions,
            );

            handler.resolve(response);
          } catch (_) {
            await _sessionRepository.clear();

            handler.next(error);
          }
        },
      ),
    );
  }

  late final Dio _dio;

  final AuthRepository _authRepository;
  final SessionRepository _sessionRepository;

  Dio get dio => _dio;
}
