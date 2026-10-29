import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/note_repository.dart';

class NoteDetailPage extends ConsumerStatefulWidget {
  const NoteDetailPage({
    super.key,
    required this.noteId,
  });

  final int noteId;

  @override
  ConsumerState<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<NoteDetailPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isInitialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _initializeData() {
    if (_isInitialized) return;
    _isInitialized = true;

    if (widget.noteId > 0) {
      final notesAsync = ref.read(notesProvider);
      notesAsync.whenData((notes) {
        final existingNote = notes.where((n) => n.id == widget.noteId).firstOrNull;
        if (existingNote != null) {
          _titleController.text = existingNote.title;
          _bodyController.text = existingNote.body;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializeData();
    final isNew = widget.noteId == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Tambah Catatan' : 'Detail Catatan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Catatan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextFormField(
                  controller: _bodyController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'Isi Catatan',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan'),
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      await ref.read(notesProvider.notifier).addNote(
                            title: _titleController.text.trim(),
                            body: _bodyController.text.trim(),
                          );
                      if (context.mounted) {
                        context.pop();
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
