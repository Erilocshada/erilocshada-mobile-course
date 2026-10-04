import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Request Notification Permission (Android 13+ & iOS)
  await requestNotificationPermission();

  // Initialize Local Notifications and FCM Foreground/Background handlers
  await initLocalNotifications();

  // Initialize FCM Token and listeners
  await initFcmToken(
    onToken: (token) async {
      debugPrint('=================================');
      debugPrint('FCM TOKEN:');
      debugPrint(token);
      debugPrint('=================================');
    },
  );

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
      initialLocation: '/',
      redirect: (
        context,
        state,
      ) {
        final authState = ref.read(authProvider);

        if (authState.isLoading) {
          return null;
        }

        final loggedIn = authState.isAuthenticated;

        final isLoginPage = state.matchedLocation == '/login';

        if (!loggedIn && !isLoginPage) {
          return '/login';
        }

        if (loggedIn && isLoginPage) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (
            context,
            state,
          ) {
            return const LoginPage();
          },
        ),
        GoRoute(
          path: '/',
          builder: (
            context,
            state,
          ) {
            return const HomePage();
          },
        ),
        GoRoute(
          path: '/pengumuman/:id',
          builder: (
            context,
            state,
          ) {
            final id = state.pathParameters['id']!;

            return AnnouncementPage(
              id: id,
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        _router.refresh();
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
