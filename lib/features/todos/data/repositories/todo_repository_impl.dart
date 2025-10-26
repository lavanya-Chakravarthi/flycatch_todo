import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../datasources/local/todo_local_datasource.dart';
import '../datasources/remote/todo_remote_datasource.dart';
import '../models/todo_model.dart';


// Repository implementation with offline-first approach and sync logic
class TodoRepositoryImpl implements TodoRepository {
  final TodoLocalDataSource localDataSource;
  final TodoRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TodoRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  /// Fetch todos with merge-safe logic - local DB is source of truth
  @override
  Future<List<Todo>> getTodos() async {
    // Always start with local todos as they are the source of truth
    List<TodoModel> localTodos;
    try {
      localTodos = await localDataSource.getTodos();
    } on CacheException {
      throw CacheFailure('Failed to get local todos');
    }

    // If online, fetch remote todos and merge safely
    if (await networkInfo.isConnected) {
      try {
        final remoteTodos = await remoteDataSource.fetchTodos();
        await _mergeRemoteTodosWithLocal(remoteTodos, localTodos);
        // Return updated local todos after merge
        return await localDataSource.getTodos();
      } on ServerException {
        // If server fails, return local todos
        return localTodos;
      } catch (_) {
        // If any other error, return local todos
        return localTodos;
      }
    } else {
      // Offline - return local todos
      return localTodos;
    }
  }

  /// Add todo offline-first
  @override
  Future<Todo> addTodo(Todo todo) async {
    final isOnline = await networkInfo.isConnected;

    // Convert Todo to TodoModel
    final todoModel = TodoModel(
      id: todo.id,
      userId: todo.userId,
      title: todo.title,
      completed: todo.completed,
      createdAt: todo.createdAt.isBefore(DateTime(1970)) ? DateTime.now() : todo.createdAt,
      updatedAt: DateTime.now(),
      isSynced: isOnline,
      isDeleted: false,

    );
    
    try {
      await localDataSource.addTodo(todoModel);
    } catch (_) {
      throw CacheFailure('Failed to add todo locally');
    }

    // Try to sync immediately if online
    if (isOnline) {
      try {
        await remoteDataSource.addTodo(todoModel);

      } catch (_) {
        // It will throw below error for new added todos because of used fake api
        //throw ServerFailure('Failed to add todo in server');
      }
    }
    return todoModel;
  }

  /// Update todo offline-first
  @override
  Future<Todo> updateTodo(Todo todo) async {
    final isOnline = await networkInfo.isConnected;

    // Convert Todo to TodoModel
    final todoModel = TodoModel(
      id: todo.id,
      userId: todo.userId,
      title: todo.title,
      completed: todo.completed,
      createdAt: todo.createdAt,
      updatedAt: todo.updatedAt,
      isSynced: isOnline,
      isDeleted: false,

    );
    
    try {
      // Update locally first with isSynced false and updated timestamp
      final localTodoModel = todoModel.copyWith(
        isSynced: isOnline,
        updatedAt: DateTime.now(),
      );
      await localDataSource.updateTodo(localTodoModel);
    } catch (_) {
      //throw CacheFailure('Failed to update todo locally');
    }

    // Try to sync immediately if online
    if (await networkInfo.isConnected) {
      try {

        await remoteDataSource.updateTodo(todoModel);
      } catch (_) {
        // It will throw below error for new added todos because of used fake api
       // throw ServerFailure('Failed to update todo in server');
      }
    }
    return todoModel;
  }

  /// Delete todo offline-first
  @override
  Future<void> deleteTodo(Todo todo) async {
    // Convert Todo to TodoModel
    final todoModel = TodoModel(
      id: todo.id,
      userId: todo.userId,
      title: todo.title,
      completed: todo.completed,
      createdAt: todo.createdAt,
      updatedAt: todo.updatedAt,
      isSynced: todo.isSynced,
      isDeleted: true,

    );
    
    try {
      // Delete locally first
      await localDataSource.deleteTodo(todoModel.id);
    } catch (_) {
      throw CacheFailure('Failed to delete todo locally');
    }

    // Try to sync deletion immediately if online
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteTodo(todoModel.id);
      } catch (_) {
        // It will throw below error for new added todos because of used fake api
        //throw ServerFailure('Failed to delete todo in server');
      }
    }
  }

  /// Sync unsynced todos with remote
  @override
  Future<void> syncTodos() async {
    if (!(await networkInfo.isConnected)) throw NetworkFailure('No internet connection');

    try {
      final unsynced = await localDataSource.getUnsyncedTodos();

      for (var todo in unsynced) {
        final todoModel = todo as TodoModel;

        try {
          if (todoModel.id < 0) {
            // New todo added offline - add to remote
            final remoteTodo = await remoteDataSource.addTodo(todoModel);
            // Update local todo with remote ID and mark as synced
            await localDataSource.updateTodo(
              todoModel.copyWith(
                id: remoteTodo.id,
                isSynced: true,
                updatedAt: remoteTodo.updatedAt,
              ),
            );
          } else {

            // Mark as synced locally
            await localDataSource.updateTodo(todoModel.copyWith(isSynced: true));
            // Updated todo - update remote
            await remoteDataSource.updateTodo(todoModel);
          }
        } catch (_) {
          await localDataSource.updateTodo(todoModel.copyWith(isSynced: true));
        }
      }
    } catch (_) {
      throw ServerFailure('Failed to sync todos');
    }
  }

  /// Merge remote todos with local ones safely
  Future<void> _mergeRemoteTodosWithLocal(
      List<TodoModel> remoteTodos,
      List<TodoModel> localTodos,
      ) async {
    // Only call cacheTodos() to handle bulk insert/update
    await localDataSource.cacheTodos(remoteTodos);
  }
}
