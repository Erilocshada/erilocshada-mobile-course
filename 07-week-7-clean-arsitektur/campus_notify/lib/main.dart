import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'providers/push_provider.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase App
  await Firebase.initializeApp();

  // ⛔ [TANPA BUILDCONTEXT]
  // Registrasi Top-Level Background Message Handler.
  // Harus dipanggil di main() sebelum runApp()
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: CampusNotifyApp(),
    ),
  );
}

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({
    super.key,
  });

  @override
  ConsumerState<CampusNotifyApp> createState() => _CampusNotifyAppState();
}

class _CampusNotifyAppState extends ConsumerState<CampusNotifyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _router = GoRouter(
      initialLocation: RoutePaths.home,
      redirect: (
        context,
        state,
      ) {
        final authState = ref.read(authProvider);

        if (authState.isLoading) {
          return null;
        }

        final loggedIn = authState.isAuthenticated;
        final isLoginPage = state.matchedLocation == RoutePaths.login;

        if (!loggedIn && !isLoginPage) {
          return RoutePaths.login;
        }

        if (loggedIn && isLoginPage) {
          return RoutePaths.home;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: RoutePaths.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: RoutePaths.home,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: RoutePaths.pengumumanDetail,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return AnnouncementPage(id: id);
          },
        ),
      ],
    );

    // Inisialisasi PushService setelah Router disiapkan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushServiceProvider).initialize(router: _router);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        _router.refresh();
      },
    );

    // Dengarkan stream navigasi dari PushService (Deeplink dari Notifikasi)
    ref.listen<AsyncValue<String>>(
      pushNavigationStreamProvider,
      (previous, next) {
        next.whenData((route) {
          if (route.isNotEmpty) {
            _router.go(route);
          }
        });
      },
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Campus Notify',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
