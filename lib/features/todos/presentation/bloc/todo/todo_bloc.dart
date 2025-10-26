import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flycatch_todo/features/todos/domain/entities/todo.dart';
import '../../../domain/usecases/sync_todo.dart';
import 'todo_event.dart';
import 'todo_state.dart';
import '../../../domain/usecases/get_todos.dart';
import '../../../domain/usecases/add_todo.dart';
import '../../../domain/usecases/update_todo.dart';
import '../../../domain/usecases/delete_todo.dart';

// BLoC for managing todo state and business logic
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final GetTodos getTodos;
  final AddTodo addTodo;
  final UpdateTodo updateTodo;
  final DeleteTodo deleteTodo;
  final SyncTodos syncTodos;

  TodoBloc({
    required this.getTodos,
    required this.addTodo,
    required this.updateTodo,
    required this.deleteTodo,
    required this.syncTodos,
  }) : super(TodoInitial()) {
    on<LoadTodosEvent>((event, emit) async {
      emit(TodoLoading());
      try {
        final todos = await getTodos();
        emit(TodoLoaded(todos: todos));
      } catch (e) {
        emit(TodoError('Failed to load todos: ${e.toString()}'));
      }
    });

    on<AddTodoEvent>((event, emit) async {
      try {
        // Show loading state while adding
        if (state is TodoLoaded) {
          emit(TodoLoaded(
            todos: (state as TodoLoaded).todos, 
            isLoading: true,
            isSyncing: (state as TodoLoaded).isSyncing,
          ));
        }
        
        final saved = await addTodo(event.todo);
        
        // Update state directly instead of reloading all todos
        if (state is TodoLoaded) {
          final currentState = state as TodoLoaded;
          final updatedTodos = List<Todo>.from(currentState.todos);
          // Add the new todo at the beginning (most recent)
          updatedTodos.insert(0, saved);
          emit(TodoLoaded(todos: updatedTodos));
        } else {
          // Fallback to reload if not in loaded state
          final todos = await getTodos();
          emit(TodoLoaded(todos: todos));
        }
      } catch (e) {
        emit(TodoError('Failed to add todo: ${e.toString()}'));
      }
    });

    on<UpdateTodoEvent>((event, emit) async {
      try {
        // Show loading state while updating
        if (state is TodoLoaded) {
          emit(TodoLoaded(
            todos: (state as TodoLoaded).todos, 
            isLoading: true,
            isSyncing: (state as TodoLoaded).isSyncing,
          ));
        }
        
        final Todo saved = await updateTodo(event.todo);
        
        // Update state directly instead of reloading all todos
        if (state is TodoLoaded) {
          final currentState = state as TodoLoaded;
          final updatedTodos = currentState.todos.map((todo) {
            if (todo.id == saved.id) {
              return saved;
            }
            return todo;
          }).toList();
          
          // Sort by updatedAt descending to maintain order
          updatedTodos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          
          emit(TodoLoaded(todos: updatedTodos));
        } else {
          // Fallback to reload if not in loaded state
          final todos = await getTodos();
          emit(TodoLoaded(todos: todos));
        }
      } catch (e) {
        emit(TodoError('Failed to update todo: ${e.toString()}'));
      }
    });

    on<DeleteTodoEvent>((event, emit) async {
      try {
        // Show loading state while deleting
        if (state is TodoLoaded) {
          emit(TodoLoaded(
            todos: (state as TodoLoaded).todos, 
            isLoading: true,
            isSyncing: (state as TodoLoaded).isSyncing,
          ));
        }
        
        await deleteTodo(event.todo);
        
        // Update state directly instead of reloading all todos
        if (state is TodoLoaded) {
          final currentState = state as TodoLoaded;
          final updatedTodos = currentState.todos.where((todo) => todo.id != event.todo.id).toList();
          emit(TodoLoaded(todos: updatedTodos));
        } else {
          // Fallback to reload if not in loaded state
          final todos = await getTodos();
          emit(TodoLoaded(todos: todos));
        }
      } catch (e) {
        emit(TodoError('Failed to delete todo: ${e.toString()}'));
      }
    });

    on<SyncTodosEvent>((event, emit) async {
      try {
        // Show syncing state
        if (state is TodoLoaded) {
          emit(TodoLoaded(
            todos: (state as TodoLoaded).todos, 
            isLoading: false,
            isSyncing: true,
            syncMessage: 'Syncing todos...',
          ));
        }
        
        await syncTodos();
        
        // Reload todos after sync to get updated data from repository
        final todos = await getTodos();
        emit(TodoLoaded(
          todos: todos,
          syncMessage: 'Sync completed successfully',
        ));
        
        // Clear sync message after a short delay
        await Future.delayed(const Duration(seconds: 2), () {
          if (state is TodoLoaded) {
            emit(TodoLoaded(todos: todos));
          }
        });
      } catch (e) {
        emit(TodoError('Failed to sync todos: ${e.toString()}'));
      }
    });
  }
}
