import 'package:flutter_riverpod/flutter_riverpod.dart';

class Todo {
  Todo(this.title, {this.done = false});
  final String title;
  final bool done;

  Todo copyWith({String? title, bool? done}) =>
      Todo(title ?? this.title, done: done ?? this.done);
}

class TodoListNotifier extends AsyncNotifier<List<Todo>> {
  @override
  Future<List<Todo>> build() async {
    await Future.delayed(const Duration(seconds: 2));
    return [Todo('Keyboard'), Todo('Mouse'), Todo('Monitor', done: true)];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> toggleDone(Todo todo) async {
    state = state.whenOrNull(
          data: (todos) => AsyncData([
            for (var i = 0; i < todos.length; i++)
              todos[i] == todo
                  ? todos[i].copyWith(done: !todos[i].done)
                  : todos[i],
          ]),
        ) ??
        state;
  }

  Future<List<Todo>> _fetch() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      Todo('Keyboard'),
      Todo('Mouse'),
      Todo('Monitor', done: true),
      Todo('Headset'),
    ];
  }
}


final todoListProvider =
    AsyncNotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);

final incompleteTodoListProvider = Provider<AsyncValue<List<Todo>>>((ref) {
  final todos = ref.watch(todoListProvider);
  return todos.whenData(
    (items) => items.where((todo) => !todo.done).toList(),
  );
});