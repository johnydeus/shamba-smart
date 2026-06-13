import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'model_update_service.dart';

// ── Result returned by MkulimaService.analyze() ────────────────────────────

class MkulimaResult {
  final String diseaseKey;
  final double confidence;
  final Map<String, dynamic> diseaseData;
  final List<Map<String, dynamic>> top3;

  /// True when the gate rejected this image (low confidence or not-a-plant).
  final bool isRejected;

  /// Human-readable Swahili rejection reason shown to the farmer.
  final String? rejectionReason;

  const MkulimaResult({
    required this.diseaseKey,
    required this.confidence,
    required this.diseaseData,
    required this.top3,
    this.isRejected = false,
    this.rejectionReason,
  });

  // Convenience getters from diseaseData JSON
  String get jinaSw => (diseaseData['jina_swahili'] as String?) ?? diseaseKey;
  String get jinaEn => (diseaseData['jina_kiingereza'] as String?) ?? '';
  String get zao => (diseaseData['zao'] as String?) ?? '';
  String get emoji => (diseaseData['emoji'] as String?) ?? '🌿';
  String get ukali => (diseaseData['ukali'] as String?) ?? '';
  String get rangiUkali => (diseaseData['rangi_ukali'] as String?) ?? '#4CAF50';
  String get dalili => (diseaseData['dalili'] as String?) ?? '';
  String get sababu => (diseaseData['sababu'] as String?) ?? '';
  String get dawa => (diseaseData['dawa'] as String?) ?? '';
  String get dawaAsili => (diseaseData['dawa_asili'] as String?) ?? '';
  String get kinga => (diseaseData['kinga'] as String?) ?? '';
  String get hatuaYaHaraka => (diseaseData['hatua_ya_haraka'] as String?) ?? '';
  String get wakatiHatari => (diseaseData['wakati_hatari'] as String?) ?? '';

  bool get isHealthy =>
      diseaseKey.toLowerCase().contains('healthy');

  bool get isUrgent =>
      ukali == 'juu sana' || ukali == 'hatari';

  Color get ukaliColor {
    try {
      final hex = rangiUkali.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF4CAF50);
    }
  }

  // Context string passed to Claude/PlantId for richer Swahili explanation
  String toClaudeContext() {
    return '[Mkulima AI v2 — Uchunguzi wa Awali]\n'
        'Ugonjwa: $jinaSw ($jinaEn)\n'
        'Zao: $zao\n'
        'Uhakika: ${(confidence * 100).toStringAsFixed(1)}%\n'
        'Ukali: $ukali\n'
        'Dalili: $dalili\n'
        'Sababu: $sababu\n';
  }

  Map<String, dynamic> toSupabaseRow() => {
        'disease_key': diseaseKey,
        'disease_swahili': jinaSw,
        'confidence': confidence,
        'ukali': ukali,
        'zao': zao,
        'top3': top3,
        'source': 'mkulima_ai_v2',
        'model_version': 'v2',
      };
}

// ── Service ─────────────────────────────────────────────────────────────────

class MkulimaService {
  static final MkulimaService _instance = MkulimaService._internal();
  factory MkulimaService() => _instance;
  MkulimaService._internal();

  Interpreter? _interpreter;
  List<String> _classNames = [];
  Map<String, dynamic> _diseases = {};
  bool _initialized = false;

  static const int _inputSize = 224;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      // Prefer a downloaded model over the bundled asset so OTA updates
      // take effect without a full app release.
      final downloadedPath = await ModelUpdateService().activePath;
      if (downloadedPath != null) {
        _interpreter = Interpreter.fromFile(File(downloadedPath));
        debugPrint('MkulimaService: loaded OTA model from $downloadedPath');
      } else {
        _interpreter = await Interpreter.fromAsset(
          'assets/mkulima_v2_best.tflite',
        );
      }

      final classJson =
          await rootBundle.loadString('assets/class_names_v2.json');
      _classNames = List<String>.from(jsonDecode(classJson) as List);

      final diseaseJson =
          await rootBundle.loadString('assets/mkulima_diseases_sw.json');
      _diseases = Map<String, dynamic>.from(jsonDecode(diseaseJson) as Map);

      _initialized = true;
      debugPrint('MkulimaService: loaded ${_classNames.length} classes');
    } catch (e) {
      debugPrint('MkulimaService init error: $e');
    }
  }

  Future<MkulimaResult?> analyze(File imageFile) async {
    if (!_initialized) await initialize();
    if (_interpreter == null || _classNames.isEmpty) return null;

    try {
      final bytes = await imageFile.readAsBytes();
      final rawImage = img.decodeImage(bytes);
      if (rawImage == null) return null;

      final resized =
          img.copyResize(rawImage, width: _inputSize, height: _inputSize);

      // Gate 1: plant check — reject if < 15% of pixels are green-dominant.
      if (_greenPixelRatio(resized) < 0.15) {
        return MkulimaResult(
          diseaseKey: 'rejected_no_plant',
          confidence: 0,
          diseaseData: const {},
          top3: const [],
          isRejected: true,
          rejectionReason:
              'Picha haina mmea wa kutosha. Piga picha karibu na majani ya mmea wako.',
        );
      }

      // Build [1, 224, 224, 3] input — MobileNetV2 normalization [-1, 1]
      final inputBuffer = Float32List(_inputSize * _inputSize * 3);
      int idx = 0;
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final pixel = resized.getPixel(x, y);
          inputBuffer[idx++] = pixel.r / 127.5 - 1.0;
          inputBuffer[idx++] = pixel.g / 127.5 - 1.0;
          inputBuffer[idx++] = pixel.b / 127.5 - 1.0;
        }
      }

      // Reshape to 4D nested list expected by tflite_flutter
      final input = _reshape4D(inputBuffer, _inputSize);
      final output = [List.filled(_classNames.length, 0.0)];

      _interpreter!.run(input, output);

      final rawScores = output[0];

      // Apply softmax only if scores look like logits (any > 1 or < 0)
      final maxRaw = rawScores.reduce(math.max);
      final minRaw = rawScores.reduce(math.min);
      final scores =
          (maxRaw > 1.0 || minRaw < 0.0) ? _softmax(rawScores) : rawScores;

      // Sort by score descending
      final indexed = List.generate(scores.length, (i) => i)
        ..sort((a, b) => scores[b].compareTo(scores[a]));

      // Top 3
      final top3 = indexed.take(3).map((i) {
        final key = i < _classNames.length ? _classNames[i] : 'Unknown';
        return {
          'disease_key': key,
          'confidence': scores[i],
          'jina_sw': (_diseases[key]?['jina_swahili'] as String?) ?? key,
          'emoji': (_diseases[key]?['emoji'] as String?) ?? '🌿',
        };
      }).toList();

      final bestIdx = indexed.first;
      final bestKey =
          bestIdx < _classNames.length ? _classNames[bestIdx] : 'Unknown';
      final bestConf = scores[bestIdx];

      // Gate 2: confidence gate — reject results below 70 %.
      if (bestConf < 0.70) {
        return MkulimaResult(
          diseaseKey: 'rejected_low_confidence',
          confidence: bestConf,
          diseaseData: const {},
          top3: top3,
          isRejected: true,
          rejectionReason:
              'Mkulima AI haijui kwa uhakika (${(bestConf * 100).toStringAsFixed(0)}%). '
              'Piga picha ya wazi ya majani ya mmea wako kwenye mwanga mzuri.',
        );
      }

      final diseaseData = Map<String, dynamic>.from(
        (_diseases[bestKey] as Map<String, dynamic>?) ??
            {'jina_swahili': bestKey, 'jina_kiingereza': bestKey},
      );

      return MkulimaResult(
        diseaseKey: bestKey,
        confidence: bestConf,
        diseaseData: diseaseData,
        top3: top3,
      );
    } catch (e) {
      debugPrint('MkulimaService analyze error: $e');
      return null;
    }
  }

  // Build nested [1][H][W][3] list from flat Float32List
  List _reshape4D(Float32List flat, int size) {
    return List.generate(1, (_) {
      return List.generate(size, (y) {
        return List.generate(size, (x) {
          final base = (y * size + x) * 3;
          return [flat[base], flat[base + 1], flat[base + 2]];
        });
      });
    });
  }

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final sum = exps.fold(0.0, (a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  // Returns the fraction of pixels that are green-dominant.
  // A pixel qualifies when green is noticeably stronger than red AND blue.
  double _greenPixelRatio(img.Image image) {
    int greenCount = 0;
    final total = image.width * image.height;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();
        if (g > r + 15 && g > b + 15 && g > 50) greenCount++;
      }
    }
    return greenCount / total;
  }
}
