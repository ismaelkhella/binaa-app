import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';

class ConnectivityService {
  final Ref _ref;
  ConnectivityService(this._ref) {
    Connectivity().onConnectivityChanged.listen((results) {
      // Check if any of the results indicate a connection
      final hasConnection = results.any((result) => result != ConnectivityResult.none);
      if (hasConnection) {
        _onConnected();
      }
    });
  }

  void _onConnected() {
    // Refresh critical data providers
    _ref.invalidate(dashboardDataProvider);
    // You can add more refreshes here if needed
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(ref);
});
