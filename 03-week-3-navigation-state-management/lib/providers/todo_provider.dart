import 'package:flutter_riverpod/flutter_riverpod.dart';

class Todo {
  const Todo(this.title, {this.done = false});

  final String title;
  final bool done;

  Todo copyWith({String? title, bool? done}) {
    return Todo(title ?? this.title, done: done ?? this.done);
  }
}

class TodoListNotifier extends AsyncNotifier<List<Todo>> {
  @override
  Future<List<Todo>> build() => _loadTodos();

  Future<void> refresh({bool simulateError = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadTodos(simulateError: simulateError),
    );
  }

  void toggleDone(Todo todo) {
    state = state.whenData(
      (todos) => [
        for (final item in todos)
          item == todo ? item.copyWith(done: !item.done) : item,
      ],
    );
  }

  Future<List<Todo>> _loadTodos({bool simulateError = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (simulateError) {
      throw Exception('Simulasi gagal terhubung ke server.');
    }
    return const [
      Todo('Riset kebutuhan pengguna'),
      Todo('Membuat wireframe'),
      Todo('Implementasi halaman utama', done: true),
      Todo('Menulis dokumentasi'),
    ];
  }
}

final todoListProvider = AsyncNotifierProvider<TodoListNotifier, List<Todo>>(
  TodoListNotifier.new,
);

final incompleteTodoListProvider = Provider<AsyncValue<List<Todo>>>((ref) {
  return ref
      .watch(todoListProvider)
      .whenData((todos) => todos.where((todo) => !todo.done).toList());
});
