import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../services/frame_throttler.dart';
import '../services/inference_isolate.dart';
import '../services/live_camera_service.dart';

/// Drives the live inference pipeline and exposes UI state.
///
/// Lifecycle:
///   [startScanning] → camera + isolate initialised → frames flow
///   [stopScanning]  → stream paused (controller still alive)
///   [dispose]       → full teardown of camera + isolate
///
/// [LiveScanProvider] is screen-scoped: create one instance per
/// [LiveScanScreen] and dispose it when the screen is disposed.
class LiveScanProvider extends ChangeNotifier {
  final _camera = LiveCameraService();
  final _inference = InferenceIsolateManager();
  final _throttler = FrameThrottler();

  // ── UI state ──────────────────────────────────────────────────────────────
  bool isScanning = false;
  bool isInitialising = false;
  String? initError;

  InferenceResult? latestResult;
  double avgInferenceMs = 0;
  int framesProcessed = 0;
  int framesDropped = 0;

  // Label smoothing: require the same top label 3 consecutive times before
  // surfacing it in the UI — prevents flickering on noisy frames.
  final List<String> _recentKeys = [];
  String? stableKey;
  String? stableLabel;
  double stableConfidence = 0;
  List<Map<String, dynamic>> stableTop3 = [];

  CameraController? get cameraController => _camera.controller;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Initialises camera + inference isolate, then starts streaming.
  Future<void> startScanning() async {
    if (isScanning || isInitialising) return;

    isInitialising = true;
    initError = null;
    notifyListeners();

    try {
      // Load model bytes and metadata in the main isolate so they can be
      // passed to the background isolate without platform-channel access.
      final modelData =
          await rootBundle.load('assets/mkulima_v2_best.tflite');
      final modelBytes = modelData.buffer.asUint8List();

      final classJson =
          await rootBundle.loadString('assets/class_names_v2.json');
      final labels = List<String>.from(jsonDecode(classJson) as List);

      final diseaseJson =
          await rootBundle.loadString('assets/mkulima_diseases_sw.json');
      final diseases =
          Map<String, dynamic>.from(jsonDecode(diseaseJson) as Map);

      // Build a flat key → Swahili name map (small, cheap to send).
      final labelToSwahili = <String, String>{
        for (final key in labels)
          key: (diseases[key]?['jina_swahili'] as String?) ?? key,
      };

      // Initialise camera.
      await _camera.initialize();

      // Spawn inference isolate — heavy; happens once per session.
      await _inference.start(
        modelBytes: modelBytes,
        labels: labels,
        labelToSwahili: labelToSwahili,
      );

      _throttler.reset();
      isInitialising = false;
      isScanning = true;
      notifyListeners();

      await _camera.startStream(_onFrame);
    } catch (e) {
      isInitialising = false;
      initError = e.toString();
      notifyListeners();
    }
  }

  /// Pauses the image stream without destroying the camera controller.
  Future<void> stopScanning() async {
    if (!isScanning) return;
    isScanning = false;
    await _camera.stopStream();
    notifyListeners();
  }

  /// Resumes the image stream (after [stopScanning]).
  Future<void> resumeScanning() async {
    if (isScanning || _camera.controller == null) return;
    _throttler.reset();
    isScanning = true;
    notifyListeners();
    await _camera.startStream(_onFrame);
  }

  /// Stops the stream, captures a still frame, returns the file path.
  /// Returns `null` if the camera is not ready.
  Future<String?> captureAndStop() async {
    await stopScanning();
    final ctrl = _camera.controller;
    if (ctrl == null || !ctrl.value.isInitialized) return null;
    try {
      final xFile = await ctrl.takePicture();
      return xFile.path;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    isScanning = false;
    await _camera.dispose();
    await _inference.dispose();
    super.dispose();
  }

  // ── Frame processing ──────────────────────────────────────────────────────

  void _onFrame(CameraImage image) async {
    if (!isScanning) return;

    if (!_throttler.shouldProcess()) {
      framesDropped++;
      return; // Drop — zero cost, native buffer released immediately.
    }

    try {
      final result = await _inference.infer(image);
      if (result == null) return;

      framesProcessed++;
      // Exponential moving average of inference time.
      avgInferenceMs = avgInferenceMs * 0.9 + result.inferenceTimeMs * 0.1;
      latestResult = result;

      // Label smoothing — only surface a result after 3 identical top keys
      // above the confidence threshold.
      _recentKeys.add(result.topKey);
      if (_recentKeys.length > 3) _recentKeys.removeAt(0);

      if (_recentKeys.length == 3 &&
          _recentKeys.toSet().length == 1 &&
          result.topConfidence > 0.50) {
        stableKey = result.topKey;
        stableLabel = result.topLabel;
        stableConfidence = result.topConfidence;
        stableTop3 = result.top3;
      }

      notifyListeners();
    } finally {
      _throttler.markComplete();
    }
  }
}
