import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/notes/presentation/pages/note_detail_page.dart';
import 'features/notes/presentation/pages/notes_page.dart';
import 'features/settings/data/repositories/app_settings_repository_impl.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catat waktu terakhir dibuka. Sengaja instansiasi langsung: ProviderScope
  // belum ada sebelum runApp, jadi tidak bisa lewat provider.
  await AppSettingsRepositoryImpl().markOpenedNow();

  runApp(const ProviderScope(child: OfflineNotesApp()));
}

final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.home,
  routes: [
    GoRoute(
      path: RoutePaths.home,
      builder: (context, state) => const NotesPage(),
    ),
    GoRoute(
      path: RoutePaths.settings,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: RoutePaths.noteDetail,
      builder: (context, state) {
        final id =
            int.tryParse(state.pathParameters['id'] ?? RoutePaths.newNoteId) ??
            0;
        return NoteDetailPage(noteId: id);
      },
    ),
  ],
);

class OfflineNotesApp extends ConsumerWidget {
  const OfflineNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider).value ?? false;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Offline Notes',
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
