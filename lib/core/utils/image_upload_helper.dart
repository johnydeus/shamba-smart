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
}

class _CompressArgs {
  final Uint8List bytes;
  final int maxWidth;
  final int quality;
  const _CompressArgs(this.bytes, this.maxWidth, this.quality);
}
