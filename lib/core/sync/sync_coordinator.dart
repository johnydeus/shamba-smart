import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../network/connectivity_service.dart';
import 'sync_status.dart';

typedef OutboxHandler = Future<bool> Function(Map<String, dynamic> item);

/// Drains outbox queues when connectivity returns or app resumes.
class SyncCoordinator extends ChangeNotifier {
  static final SyncCoordinator _instance = SyncCoordinator._();
  factory SyncCoordinator() => _instance;
  SyncCoordinator._();

  final AppDatabase _db = AppDatabase();
  final ConnectivityService _connectivity = ConnectivityService();
  final Map<String, OutboxHandler> _handlers = {};

  SyncStatus _status = const SyncStatus();
  SyncStatus get status => _status;

  StreamSubscription<bool>? _connectivitySub;
  bool _flushing = false;

  Future<void> init() async {
    await _connectivity.init();
    _updateStatus();

    _connectivitySub = _connectivity.onOnlineChanged.listen((online) {
      _updateStatus(online: online);
      if (online) flushAll();
    });
  }

  void registerHandler(String type, OutboxHandler handler) {
    _handlers[type] = handler;
  }

  Future<void> flushAll() async {
    if (_flushing || !_connectivity.isOnline) return;
    _flushing = true;
    _status = _status.copyWith(state: SyncState.syncing);
    notifyListeners();

    try {
      final pending = await _db.pendingOutbox();
      for (final item in pending) {
        if (!_connectivity.isOnline) break;

        final type = item['type'] as String;
        final handler = _handlers[type];
        if (handler == null) continue;

        final id = item['id'] as String;
        final retryCount = item['retry_count'] as int? ?? 0;

        await _db.markOutboxSending(id);
        try {
          final ok = await handler(item);
          if (ok) {
            await _db.markOutboxSent(id);
          } else {
            if (retryCount >= 5) {
              await _db.markOutboxDead(id, 'Max retries exceeded');
            } else {
              await _db.markOutboxFailed(id, 'Handler returned false');
            }
          }
        } catch (e) {
          if (retryCount >= 5) {
            await _db.markOutboxDead(id, e.toString());
          } else {
            await _db.markOutboxFailed(id, e.toString());
          }
        }
      }
    } finally {
      _flushing = false;
      await _updateStatus();
    }
  }

  Future<void> _updateStatus({bool? online}) async {
    final isOnline = online ?? _connectivity.isOnline;
    final pending = await _db.pendingCount();
    _status = SyncStatus(
      state: isOnline
          ? (_flushing ? SyncState.syncing : SyncState.idle)
          : SyncState.offline,
      pendingCount: pending,
    );
    notifyListeners();
  }

  Future<void> refreshStatus() => _updateStatus();

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
