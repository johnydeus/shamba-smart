import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Sentinel crop value meaning "let the app detect the crop" (auto-detect).
const String kAutoCrop = 'Auto';

/// Taxonomy + Swahili localization for crop image classification.
///
/// Source of truth = the SAME bundled assets the Mkulima model uses:
///   - assets/class_names_v2.json     (e.g. "Tomato___Bacterial_spot")
///   - assets/mkulima_diseases_sw.json (per-class Swahili data, incl. `zao`)
///
/// Used to build the `allowedLabels[]` taxonomy-lock list for gemini-proxy
/// (Phase 3) and to translate Gemini's English label back into the existing
/// Swahili localization. Read-only / cached; no behavior when the Gemini flag
/// is off (nothing calls this).
class ScanTaxonomy {
  static final ScanTaxonomy _instance = ScanTaxonomy._();
  factory ScanTaxonomy() => _instance;
  ScanTaxonomy._();

  Map<String, dynamic> _diseases = {}; // classKey -> { jina_swahili, jina_kiingereza, zao, ... }
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final diseaseJson =
          await rootBundle.loadString('assets/mkulima_diseases_sw.json');
      _diseases = Map<String, dynamic>.from(jsonDecode(diseaseJson) as Map);
      _loaded = true;
    } catch (e) {
      debugPrint('ScanTaxonomy load error: $e');
    }
  }

  String _en(Map e) => (e['jina_kiingereza'] as String?)?.trim() ?? '';

  /// Scan-picker crop names (kCrops) that differ from the taxonomy `zao`
  /// spelling. Normalised (lowercased) on both sides so the correct closed
  /// list is used instead of silently falling through to open detection.
  static const Map<String, String> _cropAliases = {
    'chungwa': 'machungwa / mindimu',
    'machungwa': 'machungwa / mindimu',
    'stroberri': 'strawberry',
    'straberi': 'strawberry',
  };

  /// Allowed English labels for a Swahili crop name (e.g. "Nyanya").
  /// Always includes "Healthy" and "Unknown" so Gemini can pick a safe exit.
  ///
  /// If the crop has NO taxonomy entry, returns an EMPTY list — the caller
  /// then sends no labels, which tells gemini-proxy to use OPEN identification
  /// (identify the real disease from the model's own knowledge, "Unknown" if
  /// unsure) instead of being force-locked to an unrelated crop's diseases.
  /// This is what makes coffee/cashew/etc. work without a wrong closed list.
  List<String> allowedLabelsForCrop(String cropSw) {
    final target =
        (_cropAliases[cropSw.trim().toLowerCase()] ?? cropSw.trim())
            .toLowerCase();
    final labels = <String>{};
    for (final entry in _diseases.values) {
      if (entry is! Map) continue;
      final zao = (entry['zao'] as String?)?.trim() ?? '';
      final en = _en(entry);
      if (en.isEmpty) continue;
      if (cropSw.isEmpty || zao.toLowerCase() == target) {
        labels.add(en);
      }
    }
    if (labels.isEmpty) {
      // No crop match -> empty list signals OPEN detection to the proxy.
      return const <String>[];
    }
    labels.add('Healthy');
    labels.add('Unknown');
    return labels.toList();
  }

  /// Distinct Swahili crop names that actually HAVE a disease taxonomy (the
  /// candidate list for auto-detect). Detecting only these guarantees we can
  /// then lock disease classification to that crop's diseases.
  List<String> diseaseCrops() {
    final crops = <String>{};
    for (final entry in _diseases.values) {
      if (entry is Map) {
        final zao = (entry['zao'] as String?)?.trim() ?? '';
        if (zao.isNotEmpty) crops.add(zao);
      }
    }
    return crops.toList()..sort();
  }

  /// Look up the existing Swahili localization for an English label that Gemini
  /// returned. Returns null when there's no match (caller then passes the
  /// English label through and lets safe fallbacks render).
  Map<String, dynamic>? localizeByEnglish(String englishLabel) {
    final target = englishLabel.trim().toLowerCase();
    for (final entry in _diseases.values) {
      if (entry is Map && _en(entry).toLowerCase() == target) {
        return Map<String, dynamic>.from(entry);
      }
    }
    return null;
  }
}
