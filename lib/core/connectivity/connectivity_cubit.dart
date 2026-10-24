import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// true = hay conexión a internet, false = sin conexión.
class ConnectivityCubit extends Cubit<bool> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(true) {
    _init();
  }

  Future<void> _init() async {
    final initial = await _connectivity.checkConnectivity();
    emit(_hasConnection(initial));
    _subscription =
        _connectivity.onConnectivityChanged.listen((results) {
      emit(_hasConnection(results));
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
