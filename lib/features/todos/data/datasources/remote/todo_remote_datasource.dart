import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../../core/constants.dart';
import '../../../../../core/error/exceptions.dart';
import '../../models/todo_model.dart';


class TodoRemoteDataSource {

  Future<List<TodoModel>> fetchTodos() async {
    final response = await http.get(Uri.parse(BASE_URL));

    if (response.statusCode == 200) {
      final List jsonList = json.decode(response.body);
      return jsonList.map((e) => TodoModel.fromJson(e)).toList();
    } else {
      throw ServerException();
    }
  }

  Future<TodoModel> addTodo(TodoModel todo) async {
    final response = await http.post(
      Uri.parse(BASE_URL),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(todo.toJson()),
    );
    if (response.statusCode == 201) {
      final jsonResponse = json.decode(response.body);
      return TodoModel.fromJson(jsonResponse);
    } else {
      throw ServerException();
    }
  }

  Future<void> updateTodo(TodoModel todo) async {
    final response = await http.put(
      Uri.parse('$BASE_URL/${todo.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(todo.toJson()),
    );
    if (response.statusCode != 200) throw ServerException();
  }

  Future<void> deleteTodo(int id) async {
    final response = await http.delete(Uri.parse('$BASE_URL/$id'));
    if (response.statusCode != 200) throw ServerException();
  }
}
