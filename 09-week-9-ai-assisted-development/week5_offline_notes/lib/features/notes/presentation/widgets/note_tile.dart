import 'package:flutter/material.dart';

import '../../domain/entities/note.dart';

/// Dulu didefinisikan di dalam `notes_page.dart` (file 166 baris).
/// Dipisah ke `presentation/widgets/` supaya tiap file tetap kecil dan
/// tile bisa diuji tanpa membangun seluruh halaman.
class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note, this.onTap, this.onDelete});

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
            Text(note.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
          ],
          SyncBadge(dirty: note.dirty),
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

/// Status sinkronisasi sebuah catatan. Teks dan ikon dijaga di satu tempat
/// karena test widget memeriksa keduanya.
class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key, required this.dirty});

  final bool dirty;

  @override
  Widget build(BuildContext context) {
    final color = dirty ? Theme.of(context).colorScheme.error : Colors.green;
    final label = dirty ? 'belum tersinkron' : 'tersinkron';

    return Row(
      children: [
        Icon(
          dirty ? Icons.sync_problem : Icons.cloud_done,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
