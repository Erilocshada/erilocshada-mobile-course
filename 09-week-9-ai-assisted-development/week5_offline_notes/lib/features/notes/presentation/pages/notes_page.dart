import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes.dart';
import '../../domain/entities/note.dart';
import '../providers/note_providers.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: const [SyncAction(), SettingsAction()],
      ),
      body: notesAsync.when(
        data: (notes) => NotesList(notes: notes),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => LoadError(message: '$err'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RoutePaths.note(0)),
        tooltip: 'Tambah Catatan',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NotesList extends ConsumerWidget {
  const NotesList({super.key, required this.notes});

  final List<Note> notes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notes.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada catatan.\nTekan + untuk menambah catatan.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteTile(
          note: note,
          onTap: () {
            if (note.id != null) {
              context.push(RoutePaths.note(note.id!));
            }
          },
          onDelete: () async {
            if (note.id != null) {
              await ref.read(notesProvider.notifier).deleteNote(note.id!);
            }
          },
        );
      },
    );
  }
}

class SyncAction extends ConsumerWidget {
  const SyncAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.sync),
      tooltip: 'Sinkronkan Catatan',
      onPressed: () async {
        await ref.read(notesProvider.notifier).sync();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proses sinkronisasi selesai')),
        );
      },
    );
  }
}

class SettingsAction extends StatelessWidget {
  const SettingsAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Pengaturan',
      onPressed: () => context.push(RoutePaths.settings),
    );
  }
}

class LoadError extends ConsumerWidget {
  const LoadError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Gagal memuat catatan: $message'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ref.invalidate(notesProvider),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
