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
    final notesAsync = ref.watch(filteredNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: const [SyncAction(), SettingsAction()],
      ),
      body: Column(
        children: [
          const NoteSearchField(),
          Expanded(
            child: notesAsync.when(
              data: (notes) => NotesList(
                notes: notes,
                query: ref.watch(noteSearchQueryProvider),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => LoadError(message: '$err'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RoutePaths.note(0)),
        tooltip: 'Tambah Catatan',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Kolom pencarian judul. Menyimpan teks lokal lewat controller (menjaga
/// kursor), dan memancarkan nilainya ke [noteSearchQueryProvider] sebagai
/// satu-satunya sumber kebenaran untuk penyaringan.
class NoteSearchField extends ConsumerStatefulWidget {
  const NoteSearchField({super.key});

  @override
  ConsumerState<NoteSearchField> createState() => _NoteSearchFieldState();
}

class _NoteSearchFieldState extends ConsumerState<NoteSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(noteSearchQueryProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        key: const Key('noteSearchField'),
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Cari judul catatan...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    ref.read(noteSearchQueryProvider.notifier).setQuery('');
                  },
                ),
        ),
        onChanged: (value) =>
            ref.read(noteSearchQueryProvider.notifier).setQuery(value),
      ),
    );
  }
}

class NotesList extends ConsumerWidget {
  const NotesList({super.key, required this.notes, this.query = ''});

  final List<Note> notes;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notes.isEmpty) {
      final noResults = query.trim().isNotEmpty;
      return Center(
        child: Text(
          noResults
              ? 'Tidak ada catatan yang cocok dengan "$query".'
              : 'Belum ada catatan.\nTekan + untuk menambah catatan.',
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
