import 'package:connectivity_plus/connectivity_plus.dart';

/// Reactive connectivity state service.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// Emits [true] when online, [false] when offline.
  Stream<bool> get onConnectivityChanged => _connectivity.onConnectivityChanged
      .map((results) => results.any(_isConnected));

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any(_isConnected);
  }

  bool _isConnected(ConnectivityResult r) =>
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.wifi ||
      r == ConnectivityResult.ethernet ||
      r == ConnectivityResult.vpn;
}
