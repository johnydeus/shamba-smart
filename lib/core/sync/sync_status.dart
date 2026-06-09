/// App-wide sync state exposed to UI layers.
enum SyncState { idle, offline, syncing, pending }

class SyncStatus {
  final SyncState state;
  final int pendingCount;
  final String? lastError;

  const SyncStatus({
    this.state = SyncState.idle,
    this.pendingCount = 0,
    this.lastError,
  });

  bool get isOffline => state == SyncState.offline;
  bool get isSyncing => state == SyncState.syncing;
  bool get hasPending => pendingCount > 0;

  SyncStatus copyWith({
    SyncState? state,
    int? pendingCount,
    String? lastError,
  }) =>
      SyncStatus(
        state: state ?? this.state,
        pendingCount: pendingCount ?? this.pendingCount,
        lastError: lastError,
      );
}
