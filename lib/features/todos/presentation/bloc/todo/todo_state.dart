import '../../../domain/entities/todo.dart';
import 'package:equatable/equatable.dart';

// Base class for all todo-related states
abstract class TodoState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TodoInitial extends TodoState {}

class TodoLoading extends TodoState {}

// State when todos are successfully loaded
class TodoLoaded extends TodoState { 
  final List<Todo> todos; 
  final bool isLoading;
  final bool isSyncing;
  final String? syncMessage;
  
  TodoLoaded({
    required this.todos, 
    this.isLoading = false,
    this.isSyncing = false,
    this.syncMessage,
  }); 
  
  @override 
  List<Object?> get props => [todos, isLoading, isSyncing, syncMessage]; 
}

class TodoError extends TodoState {
  final String message; 
  TodoError(this.message); 
  @override 
  List<Object?> get props => [message]; 
}
