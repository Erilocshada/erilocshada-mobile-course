import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/todo_provider.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Produk')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal memuat: $err'),
              FilledButton(
                onPressed: () => ref.invalidate(todoListProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) =>
              ListTile(title: Text(products[index])),
        ),
      ),
    );
  }
}

//   void _showAddDialog(BuildContext context, WidgetRef ref) {
//     final controller = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Tugas baru'),
//         content: TextField(controller: controller, autofocus: true),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Batal'),
//           ),
//           FilledButton(
//             onPressed: () {
//               if (controller.text.trim().isNotEmpty) {
//                 ref
//                     .read(todoListProvider.notifier)
//                     .add(controller.text.trim());
//               }
//               Navigator.pop(context);
//             },
//             child: const Text('Tambah'),
//           ),
//         ],
//       ),
//     );
//   }
// }