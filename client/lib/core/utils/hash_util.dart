import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Utility to calculate SHA-256 hashes for data integrity validation.
class HashUtil {
  HashUtil._();

  /// Computes SHA-256 hash string for raw bytes.
  static String calculateBytesSha256(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Computes SHA-256 hash streamingly for a file on disk in a background isolate.
  static Future<String> calculateFileSha256(File file) {
    final filePath = file.path;
    return Isolate.run(() async {
      final f = File(filePath);
      final output = await sha256.bind(f.openRead()).first;
      return output.toString();
    });
  }
}
