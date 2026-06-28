import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

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

  /// Allowed English labels for a Swahili crop name (e.g. "Nyanya").
  /// Always includes "Healthy" and "Unknown" so Gemini can pick a safe exit.
  /// If the crop isn't found, returns ALL known labels (still taxonomy-locked).
  List<String> allowedLabelsForCrop(String cropSw) {
    final labels = <String>{};
    for (final entry in _diseases.values) {
      if (entry is! Map) continue;
      final zao = (entry['zao'] as String?)?.trim() ?? '';
      final en = _en(entry);
      if (en.isEmpty) continue;
      if (cropSw.isEmpty || zao.toLowerCase() == cropSw.toLowerCase()) {
        labels.add(en);
      }
    }
    if (labels.isEmpty) {
      // No crop match — fall back to the full taxonomy.
      for (final entry in _diseases.values) {
        if (entry is Map) {
          final en = _en(entry);
          if (en.isNotEmpty) labels.add(en);
        }
      }
    }
    labels.add('Healthy');
    labels.add('Unknown');
    return labels.toList();
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
