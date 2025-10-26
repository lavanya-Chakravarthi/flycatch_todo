import 'package:flycatch_todo/features/todos/domain/entities/todo.dart';

import '../repositories/todo_repository.dart';

// Use case for syncing unsynced todos with remote server
class SyncTodos {
  final TodoRepository repository;
  SyncTodos(this.repository);

  Future call() async {
    return await repository.syncTodos();
  }
}
