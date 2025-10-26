import 'package:connectivity_plus/connectivity_plus.dart';

// Abstract interface for checking network connectivity
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

// Implementation of network connectivity checking
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;
  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}
