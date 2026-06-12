/// Limits how often the inference pipeline processes camera frames.
///
/// The camera produces ~30 fps.  The TFLite model needs only 2–3 fps.
/// Every frame that [shouldProcess] returns `false` for is simply dropped —
/// never queued.  Queuing frames creates unbounded memory growth because
/// CameraImage native buffers accumulate faster than they are consumed.
class FrameThrottler {
  /// 400 ms ≈ 2.5 fps inference rate.
  static const int _minIntervalMs = 400;

  int _lastProcessedMs = 0;
  bool _isProcessing = false;

  /// Returns `true` if this frame should be sent to the inference isolate.
  ///
  /// Returns `false` (drop the frame) when:
  /// - The previous inference is still running (backpressure control), OR
  /// - Less than [_minIntervalMs] has elapsed since the last processed frame.
  bool shouldProcess() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_isProcessing) return false;
    if (now - _lastProcessedMs < _minIntervalMs) return false;
    _lastProcessedMs = now;
    _isProcessing = true;
    return true;
  }

  /// Must be called when inference for the previously accepted frame completes.
  void markComplete() => _isProcessing = false;

  /// Resets throttle state — call when starting a fresh scan session.
  void reset() {
    _isProcessing = false;
    _lastProcessedMs = 0;
  }
}
