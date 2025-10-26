import '../entities/todo.dart';

abstract class TodoRepository {
  Future<List<Todo>> getTodos();
  Future<Todo> addTodo(Todo todo);
  Future<Todo> updateTodo(Todo todo);
  Future<void> deleteTodo(Todo todo);
  Future<void> syncTodos();
}
