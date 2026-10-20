import 'package:intl/intl.dart';

/// Utilities for sanitizing paths and filenames to prevent path traversal
/// and illegal file system characters across Windows, Linux, and macOS.
class FileSanitizer {
  FileSanitizer._();

  static final RegExp _illegalChars = RegExp(r'[<>:"/\\|?*\x00-\x1F]');
  static final RegExp _multiUnderscore = RegExp(r'_+');

  /// Sanitizes a string for use as a safe filename or title fragment.
  static String sanitizeFileName(String input) {
    if (input.trim().isEmpty) return 'document';

    // Remove path traversal tokens and replace spaces & illegal characters with underscore
    var clean = input
        .replaceAll('../', '')
        .replaceAll(r'..\', '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(_illegalChars, '_')
        .trim();

    clean = clean.replaceAll(_multiUnderscore, '_');
    if (clean.startsWith('_')) clean = clean.substring(1);
    if (clean.endsWith('_')) clean = clean.substring(0, clean.length - 1);

    if (clean.isEmpty) return 'document';
    // Limit length to avoid OS filename limit (typically 255 chars)
    if (clean.length > 80) clean = clean.substring(0, 80);
    return clean;
  }

  /// Formats document file name:
  /// `[ISO_DATE]_[SANITIZED_TITLE]_[UUID_SHORT].[EXTENSION]`
  static String formatManagedFileName({
    required DateTime date,
    required String title,
    required String uuid,
    required String originalExtension,
  }) {
    final dateStr = DateFormat('yyyyMMdd').format(date);
    final cleanTitle = sanitizeFileName(title);
    final shortUuid = uuid.replaceAll('-', '').substring(0, 8);
    var ext = originalExtension.trim();
    if (ext.startsWith('.')) ext = ext.substring(1);
    if (ext.isEmpty) ext = 'bin';
    ext = sanitizeFileName(ext).toLowerCase();

    return '${dateStr}_${cleanTitle}_$shortUuid.$ext';
  }
}
