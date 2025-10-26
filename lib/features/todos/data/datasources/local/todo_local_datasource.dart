import 'package:sqflite/sqflite.dart';

import '../../../domain/entities/todo.dart';
import '../../models/todo_model.dart';

class TodoLocalDataSource {
  final Database db;

  TodoLocalDataSource({required this.db});

  // cacheTodos - To add bulk data of todos list to local db in one commit with conflictAlgorithm
  Future<void> cacheTodos(List<TodoModel> todos) async {
    final existingRows = await db.query('todos');

    final existingMap = {
      for (var row in existingRows)
        row['id'] as int: TodoModel.fromDb(row),
    };

    final batch = db.batch();

    for (var todo in todos) {
      final existing = existingMap[todo.id];
      if (existing == null) {
        final now = DateTime.now();
        final newTodo = todo.copyWith(
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
          isSynced: true,
        );
        // First checks the data from local db with remote data, if any todo is new adds to query
        batch.insert(
          'todos',
          newTodo.toDb(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } else {
        // if there any update from remote todo then updates it in local db with preserved createdAt time.
        if (todo.hasChanged(existing)) {
          final updatedTodo = todo.copyWith(
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
            isSynced: true,
          );

          batch.update(
            'todos',
            updatedTodo.toDb(),
            where: 'id = ?',
            whereArgs: [todo.id],
          );
        }
      }
    }
    await batch.commit(noResult: true);
  }


  Future<List<TodoModel>> getTodos() async {
    final maps = await db.query(
      'todos',
      orderBy: 'updated_at DESC, created_at DESC', // Descending order by updatedAt, then createdAt
    );
    return maps.map((e) => TodoModel.fromDb(e)).toList();
  }

  Future<void> addTodo(TodoModel todo) async {
    // For offline-created todos with negative IDs, use a temporary positive ID
    final todoData = todo.toDb();
    if (todo.id < 0) {
      // Use timestamp-based ID for offline-created todos
      todoData['id'] = DateTime.now().millisecondsSinceEpoch;
    }
    await db.insert('todos', todoData,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTodo(TodoModel todo) async {
    await db.update('todos', todo.toDb(), where: 'id = ?', whereArgs: [todo.id]);
  }

  Future<void> deleteTodo(int id) async {
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TodoModel>> getUnsyncedTodos() async {
    final maps = await db.query('todos', where: 'is_synced = ?', whereArgs: [0]);
    return maps.map((e) => TodoModel.fromDb(e)).toList();
  }

  Future<TodoModel?> getTodoById(int id) async {
    final maps = await db.query('todos', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return TodoModel.fromDb(maps.first);
  }

  Future<void> deleteUnsyncedTodo(int id) async {
    await db.delete('todos', where: 'id = ? AND is_synced = ?', whereArgs: [id, 0]);
  }
}
