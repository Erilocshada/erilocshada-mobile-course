import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(incompleteTodoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ToDo belum selesai')),
      body: todosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal memuat: $error'),
              FilledButton(
                onPressed: () => ref.invalidate(todoListProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (todos) => ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context, index) => TodoTile(
            todo: todos[index],
            onChanged: () => ref
              .read(todoListProvider.notifier)
              .toggleDone(todos[index]),
          ),
        ),
      ),
    );
  }
}
