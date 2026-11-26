import 'dart:convert';
import 'dart:typed_data';

import 'live_backend.dart';

/// Uploads pictures to Cloudflare R2 through the API and returns the public
/// URL. Returns null when the upload fails (offline, or R2 not set up yet),
/// so callers can keep the local copy and try again later.
class Media {
  Media._();

  static String _type(Uint8List b) {
    if (b.length > 4 && b[0] == 0x89 && b[1] == 0x50) return 'image/png';
    if (b.length > 12 && b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) return 'image/webp';
    return 'image/jpeg';
  }

  static Future<String?> upload(Uint8List bytes, {String folder = 'uploads', String? fileName}) async {
    try {
      final j = await Api.send('POST', '/media/upload', {
        'base64': base64Encode(bytes),
        'mimeType': _type(bytes),
        'folder': folder,
        if (fileName != null) 'fileName': fileName,
      });
      final url = (j['url'] ?? j['imageUrl'] ?? '').toString();
      return url.startsWith('http') ? url : null;
    } catch (_) {
      return null;
    }
  }

  /// Same, for a picture kept as base64 (or a data: URL). URLs pass through.
  static Future<String?> uploadBase64(String? b64, {String folder = 'uploads'}) async {
    if (b64 == null || b64.isEmpty) return null;
    if (b64.startsWith('http')) return b64;
    try {
      return upload(base64Decode(b64.replaceFirst(RegExp(r'^data:[^;]+;base64,'), '')), folder: folder);
    } catch (_) {
      return null;
    }
  }
}
