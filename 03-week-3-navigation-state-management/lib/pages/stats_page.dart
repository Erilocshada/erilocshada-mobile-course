import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/todo_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail dan statistik')),
      body: todosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Statistik belum tersedia: $error')),
        data: (todos) {
          final doneCount = todos.where((todo) => todo.done).length;
          final incompleteCount = todos.length - doneCount;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Ringkasan produktivitas',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _StatCard(label: 'Total tugas', value: todos.length.toString()),
              _StatCard(label: 'Selesai', value: doneCount.toString()),
              _StatCard(
                label: 'Belum selesai',
                value: incompleteCount.toString(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Data diperbarui dari state Riverpod yang sama dengan halaman daftar.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}
