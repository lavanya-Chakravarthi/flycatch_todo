import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/todo.dart';
import '../bloc/todo/todo_bloc.dart';
import '../bloc/todo/todo_event.dart';
import '../bloc/todo/todo_state.dart';
import '../widgets/todo_item_widget.dart';
import '../../../../core/services/auto_sync_service.dart';

class TodoPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeToggle;
  final bool isOffline;
  final AutoSyncService autoSyncService;

  const TodoPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.isOffline,
    required this.autoSyncService,
  });

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  @override
  void initState() {
    super.initState();
    context.read<TodoBloc>().add(LoadTodosEvent());
  }

  Future<void> _handleRefresh() async {
    if (!widget.isOffline) {
      await widget.autoSyncService.manualSync(context.read<TodoBloc>());
    }
  }

  Widget _buildTodoList(TodoState state, double screenHeight) {
    if (state is TodoLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is TodoError) {
      return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: Center(child: Text(state.message)));
    }
    if (state is TodoLoaded) {
      if (state.todos.isEmpty) {
        return const Center(child: Text('No todos available'));
      }
      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.separated(
              itemCount: state.todos.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: screenHeight * 0.01),
              itemBuilder: (context, index) => TodoItemWidget(
                key: ValueKey('todo_${state.todos[index].id}'),
                todo: state.todos[index],
              ),
            ),
          ),
          if (state.isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo Tracker'),
        elevation: 5.0,
        shadowColor: Colors.black26,
        actions: [
          Switch(value: widget.isDarkMode, onChanged: widget.onThemeToggle),
        ],
      ),
      body: BlocBuilder<TodoBloc, TodoState>(
        buildWhen: (previous, current) {
          if (previous is TodoLoaded && current is TodoLoaded) {
            return previous.todos != current.todos ||
                previous.isLoading != current.isLoading ||
                previous.isSyncing != current.isSyncing ||
                previous.syncMessage != current.syncMessage;
          }
          return true;
        },
        builder: (context, state) {
          return Column(
            children: [
              if (widget.isOffline)
                Container(
                  width: double.infinity,
                  color: Colors.red,
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.015,
                    horizontal: screenWidth * 0.03,
                  ),
                  child: const Text(
                    'No Internet Connection',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (widget.autoSyncService.isSyncing ||
                  (state is TodoLoaded && state.isSyncing))
                Container(
                  width: double.infinity,
                  color: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.015,
                    horizontal: screenWidth * 0.03,
                  ),
                  child: Text(
                    state is TodoLoaded && state.syncMessage != null
                        ? state.syncMessage!
                        : 'Syncing...',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: _buildTodoList(state, screenHeight),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final titleController = TextEditingController();
          final formKey = GlobalKey<FormState>();

          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Add Todo'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: titleController,
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
                      final bloc = context.read<TodoBloc>();
                      final now = DateTime.now();
                      if (bloc.state is TodoLoaded &&
                          (bloc.state as TodoLoaded).todos.isNotEmpty) {
                        final lastTodo =
                            (bloc.state as TodoLoaded).todos.last;
                        final newTodo = lastTodo.copyWith(
                          id: now.millisecondsSinceEpoch,
                          title: titleController.text.trim(),
                          completed: false,
                          createdAt: now,
                          updatedAt: now,
                          isSynced: false,
                        );
                        bloc.add(AddTodoEvent(newTodo));
                      } else {
                        final newTodo = Todo(
                          id: now.millisecondsSinceEpoch,
                          userId: 1,
                          title: titleController.text.trim(),
                          completed: false,
                          createdAt: now,
                          updatedAt: now,
                          isSynced: false,
                        );
                        bloc.add(AddTodoEvent(newTodo));
                      }
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
        child: Icon(
          Icons.add,
          size: screenWidth > 600 ? 32 : 24,
        ),
      ),
    );
  }
}
