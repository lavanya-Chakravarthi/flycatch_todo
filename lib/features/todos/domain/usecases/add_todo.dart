import 'package:flycatch_todo/features/todos/domain/entities/todo.dart';

import '../repositories/todo_repository.dart';

// Use case for adding a new todo to repository
class AddTodo {
  final TodoRepository repository;
  AddTodo(this.repository);

  Future call(Todo todo) async {
    return await repository.addTodo(todo);
  }
}
