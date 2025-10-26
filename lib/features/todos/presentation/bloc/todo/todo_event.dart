import '../../../domain/entities/todo.dart';
import 'package:equatable/equatable.dart';

// Base class for all todo-related events
abstract class TodoEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTodosEvent extends TodoEvent {}

class AddTodoEvent extends TodoEvent { final Todo todo; AddTodoEvent(this.todo); }

class UpdateTodoEvent extends TodoEvent { final Todo todo; UpdateTodoEvent(this.todo); }

class DeleteTodoEvent extends TodoEvent { final Todo todo; DeleteTodoEvent(this.todo); }

class SyncTodosEvent extends TodoEvent {}
