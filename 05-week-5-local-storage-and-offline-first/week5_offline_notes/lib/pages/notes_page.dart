import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sinkronkan Catatan',
            onPressed: () async {
              await ref.read(notesProvider.notifier).sync();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Proses sinkronisasi selesai')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: notesAsync.when(
        data: (notes) {
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
                    context.push('/note/${note.id}');
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
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Gagal memuat catatan: $err'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(notesProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/note/0'),
        tooltip: 'Tambah Catatan',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    this.onTap,
    this.onDelete,
  });

  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        note.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.body.isNotEmpty) ...[
            Text(
              note.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
          ],
          if (note.dirty)
            Row(
              children: [
                Icon(
                  Icons.sync_problem,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  'belum tersinkron',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  Icons.cloud_done,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                const Text(
                  'tersinkron',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
        ],
      ),
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            )
          : null,
    );
  }
}
