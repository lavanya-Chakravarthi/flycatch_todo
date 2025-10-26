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
  Future<void> addTodo(Todo todo) async {
    // Convert Todo to TodoModel
    final todoModel = TodoModel(
      id: todo.id,
      userId: todo.userId,
      title: todo.title,
      completed: todo.completed,
      createdAt: todo.createdAt,
      updatedAt: todo.updatedAt,
      isSynced: todo.isSynced,
    );
    
    try {
      // Save locally first with isSynced false and updated timestamp
      final now = DateTime.now();
      final localTodoModel = todoModel.copyWith(
        isSynced: false,
        createdAt: todo.createdAt.isBefore(DateTime(1970)) ? now : todo.createdAt,
        updatedAt: now,
      );
      await localDataSource.addTodo(localTodoModel);
    } catch (_) {
      throw CacheFailure('Failed to add todo locally');
    }

    // Try to sync immediately if online
    if (await networkInfo.isConnected) {
      try {
        final remoteTodo = await remoteDataSource.addTodo(todoModel);
        // Update local todo with remote ID and mark as synced
        await localDataSource.updateTodo(
          todoModel.copyWith(
            id: remoteTodo.id,
            isSynced: true,
            updatedAt: remoteTodo.updatedAt,
          ),
        );
      } catch (_) {
        // It will throw below error for new added todos because of used fake api
        //throw ServerFailure('Failed to add todo in server');
      }
    }
  }

  /// Update todo offline-first
  @override
  Future<void> updateTodo(Todo todo) async {
    // Convert Todo to TodoModel
    final todoModel = TodoModel(
      id: todo.id,
      userId: todo.userId,
      title: todo.title,
      completed: todo.completed,
      createdAt: todo.createdAt,
      updatedAt: todo.updatedAt,
      isSynced: todo.isSynced,
    );
    
    try {
      // Update locally first with isSynced false and updated timestamp
      final localTodoModel = todoModel.copyWith(
        isSynced: false,
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
        // Mark as synced locally with updated timestamp
        await localDataSource.updateTodo(
          todoModel.copyWith(
            isSynced: true,
            updatedAt: DateTime.now(),
          ),
        );
      } catch (_) {
        // It will throw below error for new added todos because of used fake api
       // throw ServerFailure('Failed to update todo in server');
      }
    }
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
            // Updated todo - update remote
            await remoteDataSource.updateTodo(todoModel);
            // Mark as synced locally
            await localDataSource.updateTodo(todoModel.copyWith(isSynced: true));
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
    final localTodosMap = <int, TodoModel>{};
    for (final todo in localTodos) {
      localTodosMap[todo.id] = todo;
    }

    for (final remoteTodo in remoteTodos) {
      final localTodo = localTodosMap[remoteTodo.id];

      if (localTodo == null) {
        await localDataSource.addTodo(remoteTodo.copyWith(isSynced: true));
      } else {
        if (!localTodo.isSynced) {
          continue;
        } else if (remoteTodo.updatedAt.isAfter(localTodo.updatedAt)) {
          // Update local todo if remote version is newer - in this case not changes as this api is fake one.
          await localDataSource.updateTodo(remoteTodo.copyWith(isSynced: true));
        }
      }
    }
  }
}
