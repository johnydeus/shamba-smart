import 'dart:io' show Platform;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

/// Manages [CameraController] lifecycle for the live inference pipeline.
///
/// Responsibilities:
/// - Request camera permission
/// - Initialise the back camera at medium resolution (720 p)
/// - Start/stop the YUV420 (Android) / BGRA8888 (iOS) image stream
/// - Dispose cleanly in the right order (stream first, then controller)
class LiveCameraService {
  CameraController? _controller;
  bool _isStreaming = false;

  CameraController? get controller => _controller;
  bool get isStreaming => _isStreaming;

  /// Initialises the back camera and returns the ready [CameraController].
  Future<CameraController> initialize() async {
    // Request permission before touching the camera.
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      throw Exception(
          'Ruhusa ya kamera imekataliwa. Tafadhali ruhusu kamera.');
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception('Hakuna kamera inayopatikana.');

    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    // medium = ~720 p: enough detail for 224×224 model input, low memory.
    // yuv420 is the native Android format — zero conversion at capture time.
    // bgra8888 is what AVFoundation provides on iOS.
    _controller = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();

    // Lock settings to reduce per-frame work.
    await _controller!.setFocusMode(FocusMode.auto);
    await _controller!.setExposureMode(ExposureMode.auto);
    await _controller!.setFlashMode(FlashMode.off);

    return _controller!;
  }

  /// Begins streaming frames to [onFrame].  No-op if already streaming.
  Future<void> startStream(void Function(CameraImage) onFrame) async {
    if (_isStreaming || _controller == null) return;
    if (!_controller!.value.isInitialized) return;
    _isStreaming = true;
    await _controller!.startImageStream(onFrame);
  }

  /// Stops the image stream.  Safe to call when not streaming.
  Future<void> stopStream() async {
    if (!_isStreaming || _controller == null) return;
    _isStreaming = false;
    if (_controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }
  }

  /// Stops stream, then disposes the controller.
  /// Always call stopStream before dispose — the camera plugin crashes
  /// if the stream is still running when dispose() is called.
  Future<void> dispose() async {
    await stopStream();
    await _controller?.dispose();
    _controller = null;
  }
}
