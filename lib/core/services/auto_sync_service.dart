import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/todos/presentation/bloc/todo/todo_bloc.dart';
import '../../features/todos/presentation/bloc/todo/todo_event.dart';
import '../network/network_info.dart';

// Service for automatic background synchronization of todos
class AutoSyncService {
  final NetworkInfo networkInfo;
  final Connectivity connectivity;
  Timer? _periodicSyncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = false;
  bool _isSyncing = false;

  AutoSyncService({
    required this.networkInfo,
    required this.connectivity,
  });

  // Start auto-sync service
  void startAutoSync(TodoBloc todoBloc) {
    _startConnectivityMonitoring(todoBloc);
    _startPeriodicSync(todoBloc);
  }

  // Stop auto-sync service
  void stopAutoSync() {
    _periodicSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  // Start monitoring connectivity changes
  void _startConnectivityMonitoring(TodoBloc todoBloc) {
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final wasOnline = _isOnline;
        _isOnline = !results.contains(ConnectivityResult.none);

        // If we just came back online, trigger sync
        if (!wasOnline && _isOnline && !_isSyncing) {
          await _triggerSync(todoBloc);
        }
      },
    );
  }

  // Start periodic sync timer
  void _startPeriodicSync(TodoBloc todoBloc) {
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 5), // Sync every 5 minutes
      (timer) async {
        if (_isOnline && !_isSyncing) {
          await _triggerSync(todoBloc);
        }
      },
    );
  }

  // Trigger sync operation
  Future<void> _triggerSync(TodoBloc todoBloc) async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      
      // First, load todos to get latest remote data
      todoBloc.add(LoadTodosEvent());
      
      // Wait a bit for the load to complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Then sync unsynced todos
      todoBloc.add(SyncTodosEvent());
      
    } catch (e) {
      // Handle sync errors gracefully
      print('Auto-sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Manual sync trigger
  Future<void> manualSync(TodoBloc todoBloc) async {
    if (_isSyncing) return;
    await _triggerSync(todoBloc);
  }

  // Check if currently syncing
  bool get isSyncing => _isSyncing;

  // Check if online
  bool get isOnline => _isOnline;
}
