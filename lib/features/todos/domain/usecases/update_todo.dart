import 'package:flycatch_todo/features/todos/domain/entities/todo.dart';

import '../repositories/todo_repository.dart';

// Use case for updating an existing todo in repository
class UpdateTodo {
  final TodoRepository repository;
  UpdateTodo(this.repository);

  Future call(Todo todo) async {
    return await repository.updateTodo(todo);
  }
}
