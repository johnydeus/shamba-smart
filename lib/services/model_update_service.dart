import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages over-the-air TFLite model updates.
///
/// Flow:
///   1. [checkAndUpdate] is called once at app startup.
///   2. It queries `model_versions` for the latest active row.
///   3. If the remote version is newer than the locally stored version,
///      it downloads the .tflite file to the app's documents directory.
///   4. [activePath] returns the path to the best available model:
///      the downloaded file if present, otherwise the bundled asset path
///      (null → caller should use Interpreter.fromAsset).
///
/// [MkulimaService] calls [activePath] during initialize() so it
/// automatically picks up the downloaded model on the next launch.
class ModelUpdateService {
  static final ModelUpdateService _instance = ModelUpdateService._();
  factory ModelUpdateService() => _instance;
  ModelUpdateService._();

  static const _prefKeyVersion = 'mkulima_model_version';
  static const _modelFileName = 'mkulima_active.tflite';

  static SupabaseClient get _db => Supabase.instance.client;

  bool _checked = false;

  /// Full path to the downloaded model file, or null if only the bundled
  /// asset is available.
  Future<String?> get activePath async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_modelFileName');
    return (await file.exists()) ? file.path : null;
  }

  /// Call once at startup (after Supabase is initialised).
  /// Safe to call multiple times — only executes once per session.
  Future<void> checkAndUpdate() async {
    if (_checked) return;
    _checked = true;

    try {
      final rows = await _db
          .from('model_versions')
          .select('version, download_url, checksum')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .timeout(const Duration(seconds: 8));

      if ((rows as List).isEmpty) return;

      final latest = rows.first;
      final remoteVersion = latest['version'] as String?;
      final downloadUrl = latest['download_url'] as String?;

      if (remoteVersion == null || downloadUrl == null) return;

      final prefs = await SharedPreferences.getInstance();
      final localVersion = prefs.getString(_prefKeyVersion);

      if (localVersion == remoteVersion) {
        debugPrint('ModelUpdateService: already on $remoteVersion');
        return;
      }

      debugPrint('ModelUpdateService: updating $localVersion → $remoteVersion');

      final downloaded = await _download(downloadUrl);
      if (downloaded) {
        await prefs.setString(_prefKeyVersion, remoteVersion);
        debugPrint('ModelUpdateService: saved model $remoteVersion');
      }
    } catch (e) {
      // Non-fatal — app continues with bundled or previously cached model.
      debugPrint('ModelUpdateService.checkAndUpdate error: $e');
    }
  }

  Future<bool> _download(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return false;

      final dir = await getApplicationDocumentsDirectory();
      final tmpFile = File('${dir.path}/$_modelFileName.tmp');
      await tmpFile.writeAsBytes(response.bodyBytes, flush: true);

      // Atomic replace: rename tmp → active so a crash mid-download
      // never corrupts the live model file.
      await tmpFile.rename('${dir.path}/$_modelFileName');
      return true;
    } catch (e) {
      debugPrint('ModelUpdateService._download error: $e');
      return false;
    }
  }
}
