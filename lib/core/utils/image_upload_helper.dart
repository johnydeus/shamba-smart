import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Shared image compression + Supabase Storage upload used by both the
/// community feed and private chat. Compressing here is critical for farmers
/// on slow/expensive networks: a 5 MB phone photo becomes ~200–400 KB.
class ImageUploadHelper {
  static const _uuid = Uuid();

  /// Resize to [maxWidth] (keeping aspect ratio) and re-encode as JPEG.
  /// Runs the CPU-heavy work off the UI thread via [compute].
  static Future<Uint8List> compress(
    File file, {
    int maxWidth = 1080,
    int quality = 78,
  }) async {
    final bytes = await file.readAsBytes();
    return compute(_compressBytes, _CompressArgs(bytes, maxWidth, quality));
  }

  static Uint8List _compressBytes(_CompressArgs args) {
    final decoded = img.decodeImage(args.bytes);
    if (decoded == null) return args.bytes; // not an image we can read — send as-is
    final resized = decoded.width > args.maxWidth
        ? img.copyResize(decoded, width: args.maxWidth)
        : decoded;
    return Uint8List.fromList(img.encodeJpg(resized, quality: args.quality));
  }

  /// Compress [file], upload to [bucket] under [folder] with an unguessable
  /// random filename, and return the public URL. Throws on failure so callers
  /// can show a retry message and never fake a "sent" state.
  static Future<String> compressAndUpload(
    File file, {
    required String bucket,
    required String folder,
  }) async {
    final bytes = await compress(file);
    final path = '$folder/${_uuid.v4()}.jpg';

    await Supabase.instance.client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
        );

    return Supabase.instance.client.storage.from(bucket).getPublicUrl(path);
  }

  // ── Gemini scan optimization (Phase 2) ─────────────────────────────────────
  //
  // KEEP-ORIGINAL / SEND-OPTIMIZED CONTRACT:
  //  • ORIGINAL full-size image: still uploaded to Supabase Storage exactly as
  //    today (SupabaseService.saveDiagnosis -> bucket `leaf-photos`). This
  //    optimizer does NOT touch that path.
  //  • OPTIMIZED image: produced here, intended ONLY for the gemini-proxy
  //    classification request (wired in Phase 3). Smaller + metadata-free so it
  //    is cheap to send and leaks no GPS/EXIF to the model.
  //
  // Pure & testable: source file path -> optimized bytes. No network, no UI.
  // Not called by any live scan flow in this phase.

  /// Optimize [file] for a Gemini classification request: longest edge resized
  /// to ~[maxEdge]px (aspect preserved), JPEG quality [quality], and all
  /// EXIF/metadata stripped. Runs off the UI thread.
  static Future<Uint8List> optimiseForScan(
    File file, {
    int maxEdge = 1024,
    int quality = 80,
  }) async {
    final bytes = await file.readAsBytes();
    return compute(_optimiseForScanBytes, _CompressArgs(bytes, maxEdge, quality));
  }

  /// Base64 of [optimiseForScan] — convenience for gemini-proxy's `imageBase64`.
  static Future<String> optimisedBase64ForScan(
    File file, {
    int maxEdge = 1024,
    int quality = 80,
  }) async {
    final bytes = await optimiseForScan(file, maxEdge: maxEdge, quality: quality);
    return base64Encode(bytes);
  }

  static Uint8List _optimiseForScanBytes(_CompressArgs args) {
    final decoded = img.decodeImage(args.bytes);
    if (decoded == null) return args.bytes; // unreadable — return source as-is
    // Resize by the LONGEST edge so portrait & landscape both cap at maxEdge.
    final maxEdge = args.maxWidth;
    img.Image out;
    if (decoded.width >= decoded.height) {
      out = decoded.width > maxEdge
          ? img.copyResize(decoded, width: maxEdge)
          : decoded;
    } else {
      out = decoded.height > maxEdge
          ? img.copyResize(decoded, height: maxEdge)
          : decoded;
    }
    // Strip EXIF/metadata (GPS, device, orientation tags) before encoding.
    out.exif = img.ExifData();
    return Uint8List.fromList(img.encodeJpg(out, quality: args.quality));
  }

  /// Delete an uploaded image given its public URL. Derives the storage path
  /// from the URL (everything after `/object/public/<bucket>/`). Fails soft.
  static Future<void> deleteByUrl(String? publicUrl, {required String bucket}) async {
    if (publicUrl == null || publicUrl.isEmpty) return;
    try {
      final marker = '/object/public/$bucket/';
      final idx = publicUrl.indexOf(marker);
      if (idx == -1) return;
      var path = publicUrl.substring(idx + marker.length);
      // Strip any query string (e.g. cache-busting params).
      final q = path.indexOf('?');
      if (q != -1) path = path.substring(0, q);
      if (path.isEmpty) return;
      await Supabase.instance.client.storage.from(bucket).remove([path]);
    } catch (e) {
      debugPrint('ImageUploadHelper.deleteByUrl error: $e');
    }
  }
}

class _CompressArgs {
  final Uint8List bytes;
  final int maxWidth;
  final int quality;
  const _CompressArgs(this.bytes, this.maxWidth, this.quality);
}
