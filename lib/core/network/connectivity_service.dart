import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around connectivity_plus with a simple online/offline stream.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _onlineController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _subscription;

  bool get isOnline => _isOnline;
  Stream<bool> get onOnlineChanged => _onlineController.stream;

  Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(ConnectivityResult result) {
    final online = result != ConnectivityResult.none;
    if (online == _isOnline) return;
    _isOnline = online;
    _onlineController.add(online);
    debugPrint('ConnectivityService: ${online ? "online" : "offline"}');
  }

  Future<bool> checkNow() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
    return _isOnline;
  }

  void dispose() {
    _subscription?.cancel();
    _onlineController.close();
  }
}
