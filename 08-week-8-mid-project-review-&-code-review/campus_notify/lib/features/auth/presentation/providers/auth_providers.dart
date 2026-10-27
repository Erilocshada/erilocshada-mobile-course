import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../data/token_store.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/usecases/sign_in.dart';

/// ==========================================================================
/// SATU-SATUNYA TEMPAT WIRING (DI). Widget tidak pernah new Repository().
/// Arah panah: data -> domain <- presentation.
/// ==========================================================================

// Data layer: infra storage disuntikkan lewat provider, mudah diganti fake.
final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepositoryImpl(ref.watch(tokenStoreProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => const AuthRepositoryImpl(),
);

// Domain layer: use case menerima abstraksi, bukan implementasi.
final signInProvider = Provider<SignIn>(
  (ref) => SignIn(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionRepositoryProvider),
  ),
);

// Presentation layer: state untuk UI.
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
  late final SessionRepository _sessionRepository;
  late final SignIn _signIn;

  @override
  AuthState build() {
    _sessionRepository = ref.read(sessionRepositoryProvider);
    _signIn = ref.read(signInProvider);

    _checkSession();

    return const AuthState(
      isLoading: true,
    );
  }

  Future<void> _checkSession() async {
    final active = await _sessionRepository.hasActiveSession();

    state = AuthState(
      isLoading: false,
      isAuthenticated: active,
    );
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    final result = await _signIn(
      email: email,
      password: password,
    );

    if (result.failure != null) {
      // UI hanya menerima message ramah dari Failure — bukan exception mentah.
      state = AuthState(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: result.failure!.message,
      );
      return false;
    }

    state = const AuthState(
      isLoading: false,
      isAuthenticated: true,
    );
    return true;
  }

  Future<void> logout() async {
    await _sessionRepository.clear();

    state = const AuthState(
      isLoading: false,
      isAuthenticated: false,
    );
  }
}
