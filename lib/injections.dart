import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'core/network/network_info.dart';
import 'features/todos/data/datasources/local/todo_local_datasource.dart';
import 'features/todos/data/datasources/remote/todo_remote_datasource.dart';
import 'features/todos/data/repositories/todo_repository_impl.dart';
import 'features/todos/domain/repositories/todo_repository.dart';
import 'features/todos/domain/usecases/add_todo.dart';
import 'features/todos/domain/usecases/delete_todo.dart';
import 'features/todos/domain/usecases/get_todos.dart';
import 'features/todos/domain/usecases/sync_todo.dart';
import 'features/todos/domain/usecases/update_todo.dart';
import 'features/todos/presentation/bloc/todo/todo_bloc.dart';

// Service locator instance for dependency injection
final sl = GetIt.instance;

// Initialize all dependencies and register them with service locator
Future<void> init() async {
  // Bloc
  sl.registerFactory(() => TodoBloc(
    getTodos: sl(),
    addTodo: sl(),
    updateTodo: sl(),
    deleteTodo: sl(),
    syncTodos: sl(),
  ));

  // UseCases
  sl.registerLazySingleton(() => GetTodos(sl()));
  sl.registerLazySingleton(() => AddTodo(sl()));
  sl.registerLazySingleton(() => UpdateTodo(sl()));
  sl.registerLazySingleton(() => DeleteTodo(sl()));
  sl.registerLazySingleton(() => SyncTodos(sl()));

  // Repository
  sl.registerLazySingleton<TodoRepository>(
        () => TodoRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  final db = await openDatabase(
    join(await getDatabasesPath(), 'todo.db'),
    version: 2,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE todos(
          id INTEGER PRIMARY KEY,
          userId INTEGER,
          title TEXT,
          completed INTEGER,
          created_at TEXT,
          updated_at TEXT,
          is_synced INTEGER,
          is_deleted INTEGER
        )
      ''');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        // Add created_at column for existing databases
        await db.execute('ALTER TABLE todos ADD COLUMN created_at TEXT');
        // Set created_at to updated_at for existing records
        await db.execute('UPDATE todos SET created_at = updated_at WHERE created_at IS NULL');
      }
    },
  );
  sl.registerLazySingleton(() => TodoLocalDataSource(db: db));
  sl.registerLazySingleton(() => TodoRemoteDataSource());

  // Network Info
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(Connectivity()));
}