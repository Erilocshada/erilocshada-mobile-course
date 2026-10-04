import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/token_store.dart';

final tokenStoreProvider = Provider<TokenStore>(
      (ref) {
    return TokenStore();
  },
);

final authRepositoryProvider =
Provider<AuthRepository>(
      (ref) {
    return AuthRepository();
  },
);

final authProvider =
NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated:
      isAuthenticated ?? this.isAuthenticated,
      errorMessage:
      clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final TokenStore _tokenStore;
  late final AuthRepository _authRepository;

  @override
  AuthState build() {
    _tokenStore = ref.read(tokenStoreProvider);
    _authRepository = ref.read(
      authRepositoryProvider,
    );

    _checkLogin();

    return const AuthState(
      isLoading: true,
    );
  }


  Future<void> _checkLogin() async {
    final accessToken =
    await _tokenStore.getAccessToken();

    if (accessToken != null &&
        accessToken.isNotEmpty) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
      );
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final session =
      await _authRepository.login(
        email: email,
        password: password,
      );

      await _tokenStore.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: e.toString(),
      );

      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStore.clear();

    state = const AuthState(
      isLoading: false,
      isAuthenticated: false,
    );
  }
}