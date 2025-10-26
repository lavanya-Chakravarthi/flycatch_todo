import '../../domain/entities/todo.dart';

class TodoModel extends Todo {
  const TodoModel({
    required int id,
    required int userId,
    required String title,
    required bool completed,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isSynced,
    required bool isDeleted,
  }) : super(
    id: id,
    userId: userId,
    title: title,
    completed: completed,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isSynced: isSynced,
      isDeleted:isDeleted
  );

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      completed: json['completed'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: true, isDeleted: false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'completed': completed,
  };

  factory TodoModel.fromDb(Map<String, dynamic> dbJson) => TodoModel(
    id: dbJson['id'],
    userId: dbJson['userId'],
    title: dbJson['title'],
    completed: dbJson['completed'] == 1,
    createdAt: dbJson['created_at'] != null
        ? DateTime.parse(dbJson['created_at'])
        : DateTime.parse(dbJson['updated_at']), // Fallback to updated_at for existing records
    updatedAt: DateTime.parse(dbJson['updated_at']),
    isSynced: (dbJson['is_synced'] ?? 0) == 1, isDeleted: (dbJson['is_deleted'] ?? 0) == 1,

  );

  Map<String, dynamic> toDb() => {
    'id': id,
    'userId': userId,
    'title': title,
    'completed': completed ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_synced': isSynced ? 1 : 0,
    'is_deleted': isDeleted ? 1 : 0,
  };

  TodoModel copyWith({
    int? id,
    int? userId,
    String? title,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return TodoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }


  bool hasChanged(TodoModel other) {
    return title != other.title;
  }
}
