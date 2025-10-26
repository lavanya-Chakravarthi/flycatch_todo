import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/todo.dart';
import '../bloc/todo/todo_bloc.dart';
import '../bloc/todo/todo_event.dart';

// Widget for displaying individual todo items with edit/delete actions
class TodoItemWidget extends StatelessWidget {
  final Todo todo;

  const TodoItemWidget({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final iconSize = screenWidth > 600 ? 32.0 : 24.0;
    final smallIconSize = screenWidth > 600 ? 20.0 : 14.0;
    final fontSize = screenWidth > 600 ? 18.0 : 14.0;
    final subtitleFontSize = screenWidth > 600 ? 14.0 : 11.0;
    final horizontalMargin = screenWidth * 0.03;
    final verticalMargin = screenHeight * 0.008;

    return Card(
      key: ValueKey('todo_${todo.id}'),
      margin: EdgeInsets.symmetric(
        horizontal: horizontalMargin,
        vertical: verticalMargin,
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: () {
            context.read<TodoBloc>().add(
              UpdateTodoEvent(
                todo.copyWith(
                  completed: !todo.completed,
                  updatedAt: DateTime.now(),
                  isSynced: false,
                ),
              ),
            );
          },
          child: Icon(
            todo.completed ? Icons.check_circle : Icons.hourglass_top_sharp,
            color: todo.completed ? Colors.green : Colors.orange,
            size: iconSize,
          ),
        ),
        title: GestureDetector(
          onTap: () {
            showDialog(
              barrierDismissible: false,
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: Text(
                      "Todo",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: Text(todo.title),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text("OK"),
                      ),
                    ],
                  ),
            );
          },
          child: Text(
            todo.title,
            style: TextStyle(
              fontSize: fontSize,
              decoration: todo.completed ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!todo.isSynced)
              Row(
                children: [
                  Icon(
                    Icons.sync_disabled_outlined,
                    size: smallIconSize,
                    color: Colors.orange,
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Text(
                    'Not synced',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            SizedBox(height: screenHeight * 0.003),
            Text(
              _formatDateTime(todo.updatedAt),
              style: TextStyle(color: Colors.grey, fontSize: subtitleFontSize),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, size: iconSize),
              onPressed: () async {
                final controller = TextEditingController(text: todo.title);
                final formKey = GlobalKey<FormState>();

                await showDialog(
                  context: context,
                  builder:
                      (ctx) => SingleChildScrollView(
                        child: AlertDialog(
                          title: const Text('Edit Todo'),
                          content: Form(
                            key: formKey,
                            child: TextFormField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: 'Enter todo title',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Todo title cannot be empty';
                                }
                                return null;
                              },
                              autofocus: true,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  context.read<TodoBloc>().add(
                                    UpdateTodoEvent(
                                      todo.copyWith(
                                        title: controller.text.trim(),
                                        updatedAt: DateTime.now(),
                                        isSynced: false,
                                      ),
                                    ),
                                  );
                                  Navigator.pop(ctx);
                                }
                              },
                              child: const Text('Update'),
                            ),
                          ],
                        ),
                      ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, size: iconSize),
              onPressed: () {
                context.read<TodoBloc>().add(DeleteTodoEvent(todo));
              },
            ),
          ],
        ),
      ),
    );
  }

  // Format timestamp to show relative time (e.g., "2h ago")
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
