import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: todosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Gagal memuat: $error')),
        data: (todos) {
          final doneCount = todos.where((todo) => todo.done).length;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Total tugas: ${todos.length}'),
                Text('Selesai: $doneCount'),
                Text('Belum selesai: ${todos.length - doneCount}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
