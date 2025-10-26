import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

// Use case for retrieving all todos from repository
class GetTodos {
  final TodoRepository repository;
  GetTodos(this.repository);

  Future<List<Todo>> call() async {
    return await repository.getTodos();
  }
}
