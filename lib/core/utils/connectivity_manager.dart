import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityManager {
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _checker = InternetConnectionChecker();

  StreamController<bool>? _controller;
  StreamSubscription? _subscription;

  /// Broadcast stream of true=online, false=offline.
  Stream<bool> get onConnectivityChanged {
    _controller ??= StreamController<bool>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    return _controller!.stream;
  }

  void _startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      (dynamic res) async {
        bool hasNetwork = false;
        if (res is List) {
          hasNetwork = res.any((r) => r != ConnectivityResult.none);
        } else {
          hasNetwork = res != ConnectivityResult.none;
        }

        if (hasNetwork) {
          // Double-check with actual internet ping
          final hasInternet = await _checker.hasConnection;
          _controller?.add(hasInternet);
        } else {
          _controller?.add(false);
        }
      },
    );
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// One-shot check.
  Future<bool> get isConnected async {
    final dynamic res = await _connectivity.checkConnectivity();
    if (res is List) {
      if (res.every((r) => r == ConnectivityResult.none)) {
        return false;
      }
    } else if (res == ConnectivityResult.none) {
      return false;
    }
    return _checker.hasConnection;
  }

  void dispose() {
    _subscription?.cancel();
    _controller?.close();
  }
}
