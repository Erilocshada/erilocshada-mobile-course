import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient({
    required AuthRepository authRepo,
    required TokenStore tokenStorage,
  })  : _authRepository = authRepo,
        _tokenStore = tokenStorage {
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
          await _tokenStore.getAccessToken();

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
            await _tokenStore.getRefreshToken();

            if (refreshToken == null ||
                refreshToken.isEmpty) {
              await _tokenStore.clear();

              handler.next(error);
              return;
            }

            final newAccessToken =
            await _authRepository.refresh(
              refreshToken,
            );

            await _tokenStore.saveTokens(
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
            await _tokenStore.clear();

            handler.next(error);
          }
        },
      ),
    );
  }

  late final Dio _dio;

  final AuthRepository _authRepository;
  final TokenStore _tokenStore;

  Dio get dio => _dio;
}
