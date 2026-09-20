import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Detecta cuándo se restablece la conexión a internet después de haberse
/// perdido, para poder reanudar sincronización automáticamente (RQ-57).
class ConnectivityService {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOffline = false;

  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Registra [onRestored] para que se ejecute cada vez que la conexión
  /// pasa de "sin internet" a "con internet".
  Future<void> listenForReconnection(void Function() onRestored) async {
    final initial = await _connectivity.checkConnectivity();
    _isOffline = _isNone(initial);

    await _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final offlineNow = _isNone(results);
      if (_isOffline && !offlineNow) {
        onRestored();
      }
      _isOffline = offlineNow;
    });
  }

  bool _isNone(List<ConnectivityResult> results) =>
      results.every((r) => r == ConnectivityResult.none);

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}