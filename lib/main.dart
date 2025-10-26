import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/todos/presentation/bloc/todo/todo_bloc.dart';
import 'features/todos/presentation/bloc/todo/todo_event.dart';
import 'features/todos/presentation/pages/todo_page.dart';
import 'core/services/auto_sync_service.dart';
import 'injections.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initializes dependencies
  await di.init();
  runApp(const MyApp());
}

// this widget has theme management and connectivity monitoring
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;
  late final Connectivity _connectivity;
  late final Stream<List<ConnectivityResult>> _connectivityStream;
  late final AutoSyncService _autoSyncService;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _autoSyncService = AutoSyncService(
      networkInfo: di.sl(),
      connectivity: _connectivity,
    );
  }

  @override
  void dispose() {
    _autoSyncService.stopAutoSync();
    super.dispose();
  }

  // Load saved theme preference from device storage
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  // Toggle between light and dark theme, saving preference
  void _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = value;
      prefs.setBool('isDarkMode', value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: _connectivityStream,
      builder: (context, snapshot) {
        final isOffline = snapshot.data?.contains(ConnectivityResult.none) ?? true;
        return MultiBlocProvider(
            providers: [
            BlocProvider<TodoBloc>(
            create: (_) {
              final bloc = di.sl<TodoBloc>();
              // Start auto-sync when bloc is created
              _autoSyncService.startAutoSync(bloc);
              return bloc..add(LoadTodosEvent());
            },
        ),
        // Add more blocs here
        ],
        child: MaterialApp(
              title: 'ToDo Tracker',
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
              debugShowCheckedModeBanner: false,
              home: TodoPage(
                isDarkMode: isDarkMode,
                onThemeToggle: _toggleTheme,
                isOffline: isOffline,
                autoSyncService: _autoSyncService,
              ),
            )

        );
      },
    );
  }
}