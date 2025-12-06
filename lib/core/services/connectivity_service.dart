import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity status enum
enum ConnectivityStatus { online, offline, checking }

/// Provider for connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Provider for connectivity status stream
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.statusStream;
});

/// Provider for current connectivity status
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityStatusProvider);
  return status.when(
    data: (status) => status == ConnectivityStatus.online,
    loading: () => true, // Assume online while checking
    error: (_, __) => false,
  );
});

/// Service to monitor network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus.checking;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService() {
    _init();
  }

  /// Initialize connectivity monitoring
  Future<void> _init() async {
    // Check initial connectivity
    await checkConnectivity();

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  /// Get the status stream
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Get current status
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Check if currently online
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Check if currently offline
  bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  /// Check current connectivity status
  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      _currentStatus = ConnectivityStatus.checking;
      _statusController.add(_currentStatus);

      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
      return _currentStatus;
    } catch (e) {
      _currentStatus = ConnectivityStatus.offline;
      _statusController.add(_currentStatus);
      return _currentStatus;
    }
  }

  /// Update status based on connectivity results
  void _updateStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      _currentStatus = ConnectivityStatus.offline;
    } else {
      _currentStatus = ConnectivityStatus.online;
    }
    _statusController.add(_currentStatus);
  }

  /// Wait for connectivity to be restored
  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (isOnline) return true;

    try {
      await statusStream
          .where((status) => status == ConnectivityStatus.online)
          .first
          .timeout(timeout);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
