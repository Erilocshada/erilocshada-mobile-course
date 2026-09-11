import 'package:flutter/material.dart';
import '../providers/todo_provider.dart';

class TodoTile extends StatelessWidget {
  const TodoTile({required this.todo, required this.onChanged, super.key});

  final Todo todo;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
        value: todo.done,
        onChanged: (_) => onChanged(),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.done ? TextDecoration.lineThrough : null,
          ),
        ),
      );
}
