final authStateProvider =
AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.watch(tokenStoreProvider).readAccess();
    return token != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      await ref
          .read(tokenStoreProvider)
          .save(access: session.access, refresh: session.refresh);
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    ref.invalidateSelf();
  }
}
GoRouter(
  redirect: (context, state) {
    final loggedIn =
      container.read(authStateProvider).value ?? false;
    final goingLogin = state.matchedLocation == '/login';
      if (!loggedIn && !goingLogin) return '/login';
      if (loggedIn && goingLogin) return '/';
return null;
},
routes: [
  GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
  GoRoute(path: '/', builder: (_, __) => const HomePage()),
GoRoute(
  path: '/pengumuman/:id',
  builder: (_, s) =>
  AnnouncementPage(id: s.pathParameters['id'] ?? ''),
    ),
  ],
);