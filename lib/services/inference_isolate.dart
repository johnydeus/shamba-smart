import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

// ─────────────────────────────────────────────────────────────
// Wire types — must only contain sendable Dart values
// (primitives, TypedData, SendPort, List/Map of the above).
// ─────────────────────────────────────────────────────────────

/// Payload sent from the main isolate to the inference worker.
class InferenceRequest {
  // Android YUV420 planes (null on iOS).
  final Uint8List? yPlane;
  final Uint8List? uPlane;
  final Uint8List? vPlane;
  final int yRowStride;
  final int uvRowStride;
  final int uvPixelStride;

  // iOS BGRA8888 single plane (null on Android).
  final Uint8List? bgraPlane;
  final int bgraRowStride;

  // Common.
  final bool isBgra;
  final int width;
  final int height;

  // Where to send the result back.
  final SendPort replyPort;

  const InferenceRequest({
    this.yPlane,
    this.uPlane,
    this.vPlane,
    this.yRowStride = 0,
    this.uvRowStride = 0,
    this.uvPixelStride = 1,
    this.bgraPlane,
    this.bgraRowStride = 0,
    required this.isBgra,
    required this.width,
    required this.height,
    required this.replyPort,
  });
}

/// Result from the inference worker sent back to the main isolate.
class InferenceResult {
  final String topLabel; // Swahili display name
  final String topKey; // raw class key
  final double topConfidence;
  /// List of maps with keys 'label' (Swahili), 'key' (raw), 'confidence'.
  final List<Map<String, dynamic>> top3;
  final int inferenceTimeMs;
  final bool isHealthy;

  const InferenceResult({
    required this.topLabel,
    required this.topKey,
    required this.topConfidence,
    required this.top3,
    required this.inferenceTimeMs,
    required this.isHealthy,
  });
}

// ─────────────────────────────────────────────────────────────
// Isolate initialisation payload
// ─────────────────────────────────────────────────────────────

class _IsolateInit {
  final SendPort mainSendPort;
  final Uint8List modelBytes; // loaded in main isolate via rootBundle
  final List<String> labels; // class_names_v2.json
  final Map<String, String> labelToSwahili; // key → jina_swahili
  final RootIsolateToken rootToken;

  const _IsolateInit({
    required this.mainSendPort,
    required this.modelBytes,
    required this.labels,
    required this.labelToSwahili,
    required this.rootToken,
  });
}

// ─────────────────────────────────────────────────────────────
// Manager — lives on the main isolate
// ─────────────────────────────────────────────────────────────

/// Manages a long-lived background [Isolate] that runs TFLite inference.
///
/// Key design decisions:
/// - The isolate is spawned ONCE per scan session, not per frame.
///   Spawning costs ~50–100 ms and loads the model — never do it per frame.
/// - Model bytes are loaded in the main isolate and passed across the
///   isolate boundary as [Uint8List] so [Interpreter.fromBuffer] can be
///   used inside the worker — this avoids platform-channel dependency.
/// - Input/output tensors are pre-allocated once inside the worker and
///   reused every frame (zero GC in the hot inference path).
/// - CameraImage plane bytes are copied before crossing the boundary
///   because the camera plugin recycles native buffers after the callback.
class InferenceIsolateManager {
  Isolate? _isolate;
  SendPort? _sendPort;
  final _readyCompleter = Completer<void>();

  bool _started = false;

  /// Spawns the worker isolate and waits until it has loaded the model.
  ///
  /// [modelBytes]   — raw bytes of the .tflite asset.
  /// [labels]       — ordered list of class names (class_names_v2.json).
  /// [labelToSwahili] — map from class key → Swahili disease name.
  Future<void> start({
    required Uint8List modelBytes,
    required List<String> labels,
    required Map<String, String> labelToSwahili,
  }) async {
    if (_started) return;
    _started = true;

    final receivePort = ReceivePort();

    _isolate = await Isolate.spawn(
      _workerEntry,
      _IsolateInit(
        mainSendPort: receivePort.sendPort,
        modelBytes: modelBytes,
        labels: labels,
        labelToSwahili: labelToSwahili,
        rootToken: RootIsolateToken.instance!,
      ),
      errorsAreFatal: false,
    );

    // First message from the worker is its SendPort; subsequent messages
    // are InferenceResult or error strings.
    final sub = receivePort.listen((msg) {
      if (msg is SendPort) {
        _sendPort = msg;
        if (!_readyCompleter.isCompleted) _readyCompleter.complete();
      }
    });

    await _readyCompleter.future;
    sub.cancel();
  }

  /// Sends one [CameraImage] for inference and returns the result.
  Future<InferenceResult?> infer(CameraImage image) async {
    if (_sendPort == null) return null;

    final replyPort = ReceivePort();

    // Copy plane bytes — CameraImage native buffers are recycled by the
    // camera plugin once this callback returns, so we MUST copy before
    // crossing the isolate boundary.
    final InferenceRequest req;
    final isBgra = image.format.group == ImageFormatGroup.bgra8888 ||
        image.planes.length == 1;

    if (isBgra) {
      req = InferenceRequest(
        isBgra: true,
        bgraPlane: Uint8List.fromList(image.planes[0].bytes),
        bgraRowStride: image.planes[0].bytesPerRow,
        width: image.width,
        height: image.height,
        replyPort: replyPort.sendPort,
      );
    } else {
      req = InferenceRequest(
        isBgra: false,
        yPlane: Uint8List.fromList(image.planes[0].bytes),
        uPlane: Uint8List.fromList(image.planes[1].bytes),
        vPlane: Uint8List.fromList(image.planes[2].bytes),
        yRowStride: image.planes[0].bytesPerRow,
        uvRowStride: image.planes[1].bytesPerRow,
        uvPixelStride: image.planes[1].bytesPerPixel ?? 1,
        width: image.width,
        height: image.height,
        replyPort: replyPort.sendPort,
      );
    }

    _sendPort!.send(req);

    final result = await replyPort.first;
    replyPort.close();

    return result is InferenceResult ? result : null;
  }

  /// Shuts down the worker isolate.
  Future<void> dispose() async {
    _sendPort?.send('dispose');
    await Future.delayed(const Duration(milliseconds: 50));
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _sendPort = null;
    _started = false;
  }

  // ─────────────────────────────────────────────────────────
  // Worker isolate entry — runs entirely in background thread
  // ─────────────────────────────────────────────────────────

  static Future<void> _workerEntry(_IsolateInit init) async {
    // Required so platform channels work from background isolates.
    BackgroundIsolateBinaryMessenger.ensureInitialized(init.rootToken);

    // Load interpreter from bytes — avoids platform-channel asset lookup
    // and works reliably in a background isolate.
    final options = InterpreterOptions()..threads = 2;
    // fromBuffer is synchronous in tflite_flutter ^0.12.0 (pure FFI, no
    // platform channel needed — safe to call from a background isolate).
    final interpreter = Interpreter.fromBuffer(
      init.modelBytes,
      options: options,
    );

    final commandPort = ReceivePort();
    init.mainSendPort.send(commandPort.sendPort);

    final labelCount = init.labels.length;

    // ── Pre-allocate reusable buffers (allocated ONCE, reused every frame) ──
    //
    // inputNested: [1][224][224][3] nested List — pre-allocated and mutated
    //   in-place each frame so interpreter.run() sees zero new allocations.
    //
    // outputList: [1 × Float32List(n)] — interpreter writes scores in-place.
    final inputNested = List.generate(
      1,
      (_) => List.generate(
        _kSize,
        (_) => List.generate(
          _kSize,
          (_) => List<double>.filled(3, 0.0),
        ),
      ),
    );
    final outputList = [Float32List(labelCount)];

    // Main inference loop — processes InferenceRequests one at a time.
    await for (final msg in commandPort) {
      if (msg == 'dispose') {
        interpreter.close();
        commandPort.close();
        Isolate.exit();
      }

      if (msg is! InferenceRequest) continue;

      final sw = Stopwatch()..start();

      // Fill inputNested in a single pass (no intermediate Image objects).
      if (msg.isBgra) {
        _bgraToInput(msg, inputNested);
      } else {
        _yuv420ToInput(msg, inputNested);
      }

      // Run TFLite inference.
      interpreter.run(inputNested, outputList);
      sw.stop();

      // Extract top-3 sorted by confidence.
      final scores = outputList[0];
      final indexed = List.generate(labelCount, (i) => i)
        ..sort((a, b) => scores[b].compareTo(scores[a]));

      final top3 = indexed.take(3).map((i) {
        final key = i < init.labels.length ? init.labels[i] : 'Unknown';
        return <String, dynamic>{
          'key': key,
          'label': init.labelToSwahili[key] ?? key,
          'confidence': scores[i],
        };
      }).toList();

      final bestKey =
          indexed.first < init.labels.length ? init.labels[indexed.first] : 'Unknown';
      final bestConf = scores[indexed.first];
      final bestLabel = init.labelToSwahili[bestKey] ?? bestKey;

      msg.replyPort.send(InferenceResult(
        topKey: bestKey,
        topLabel: bestLabel,
        topConfidence: bestConf,
        top3: top3,
        inferenceTimeMs: sw.elapsedMilliseconds,
        isHealthy: bestKey.toLowerCase().contains('healthy'),
      ));
    }
  }

  // ── Single-pass YUV420 → normalised MobileNetV2 input ──────────────────
  //
  // Converts from camera YUV420 directly into the pre-allocated [out]
  // nested list.  Uses ITU-R BT.601 coefficients.
  // Normalisation: [-1, 1] to match the existing MkulimaService model.
  //
  // Single pass = no intermediate Image object = zero GC.
  static const int _kSize = 224;

  static void _yuv420ToInput(
    InferenceRequest req,
    List inputNested,
  ) {
    final scaleX = req.width / _kSize;
    final scaleY = req.height / _kSize;

    for (int ty = 0; ty < _kSize; ty++) {
      final sy = (ty * scaleY).toInt();
      final yRow = sy * req.yRowStride;
      final uvRow = (sy ~/ 2) * req.uvRowStride;

      for (int tx = 0; tx < _kSize; tx++) {
        final sx = (tx * scaleX).toInt();
        final yIdx = yRow + sx;
        final uvIdx = uvRow + (sx ~/ 2) * req.uvPixelStride;

        final y = req.yPlane![yIdx].toDouble();
        final u = req.uPlane![uvIdx].toDouble() - 128;
        final v = req.vPlane![uvIdx].toDouble() - 128;

        // ITU-R BT.601
        final r = (y + 1.402 * v).clamp(0.0, 255.0);
        final g = (y - 0.344 * u - 0.714 * v).clamp(0.0, 255.0);
        final b = (y + 1.772 * u).clamp(0.0, 255.0);

        // MobileNetV2 normalisation: [0,255] → [-1, 1]
        final pixel = inputNested[0][ty][tx] as List<double>;
        pixel[0] = r / 127.5 - 1.0;
        pixel[1] = g / 127.5 - 1.0;
        pixel[2] = b / 127.5 - 1.0;
      }
    }
  }

  // ── Single-pass BGRA8888 → normalised MobileNetV2 input ────────────────
  static void _bgraToInput(
    InferenceRequest req,
    List inputNested,
  ) {
    final scaleX = req.width / _kSize;
    final scaleY = req.height / _kSize;

    for (int ty = 0; ty < _kSize; ty++) {
      final sy = (ty * scaleY).toInt();
      for (int tx = 0; tx < _kSize; tx++) {
        final sx = (tx * scaleX).toInt();
        final base = sy * req.bgraRowStride + sx * 4;

        final b = req.bgraPlane![base].toDouble();
        final g = req.bgraPlane![base + 1].toDouble();
        final r = req.bgraPlane![base + 2].toDouble();
        // base + 3 is alpha — ignored.

        final pixel = inputNested[0][ty][tx] as List<double>;
        pixel[0] = r / 127.5 - 1.0;
        pixel[1] = g / 127.5 - 1.0;
        pixel[2] = b / 127.5 - 1.0;
      }
    }
  }
}
