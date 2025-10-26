import 'package:flycatch_todo/features/todos/domain/entities/todo.dart';

import '../repositories/todo_repository.dart';

// Use case for deleting a todo from repository
class DeleteTodo {
  final TodoRepository repository;
  DeleteTodo(this.repository);

  Future call(Todo todo) async {
    return await repository.deleteTodo(todo);
  }
}
