import 'package:equatable/equatable.dart';

// Core todo entity representing a task with sync status
class Todo extends Equatable {
  final int id;
  final int userId;
  final String title;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const Todo({
    required this.id,
    required this.userId,
    required this.title,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
  });

  // Create a copy of this todo with updated fields
   Todo copyWith({
    int? id,
    int? userId,
    String? title,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Todo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [id, userId, title, completed, createdAt, updatedAt, isSynced];
}
