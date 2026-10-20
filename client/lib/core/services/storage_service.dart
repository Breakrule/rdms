import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../utils/file_sanitizer.dart';
import '../utils/hash_util.dart';
import '../utils/mime_detector.dart';

class ManagedFileInfo {
  final String localFilePath;
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final String sha256Hash;

  const ManagedFileInfo({
    required this.localFilePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.sha256Hash,
  });
}

/// Service managing custom local file directory, path persistence,
/// and safe local file storage operations.
class LocalStorageService {
  String? _customBasePath;

  /// Async resolver supplied by the caller (usually
  /// StorageRootService.activePath) so the chosen folder survives
  /// restart. Precedence: this session's [setCustomBasePath] override,
  /// then the persisted value, then the app documents directory.
  final Future<String?> Function()? _persistentPathResolver;

  static const _uuid = Uuid();

  LocalStorageService({
    this._customBasePath,
    this._persistentPathResolver,
  });

  /// Sets or updates the configured custom base directory for THIS
  /// session. Callers that want the choice to persist across restarts
  /// must ALSO write through StorageRootService.setActivePath; keeping
  /// the two responsibilities apart is what makes Phase 1.2 safe
  /// relocation possible (a move can flip the DB row atomically with
  /// the copy-verify step).
  Future<void> setCustomBasePath(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _customBasePath = path;
  }

  /// Returns current active storage directory path.
  /// Falls back to application documents directory if neither the
  /// session override nor a persistent root is configured.
  Future<String> getStorageDirectoryPath() async {
    if (_customBasePath != null && _customBasePath!.isNotEmpty) {
      return _customBasePath!;
    }
    final persistent = await _persistentPathResolver?.call();
    if (persistent != null && persistent.isNotEmpty) {
      return persistent;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final defaultDir = Directory(p.join(appDir.path, 'DocumentStorage'));
    if (!await defaultDir.exists()) {
      await defaultDir.create(recursive: true);
    }
    return defaultDir.path;
  }

  /// Verifies if the storage media is mounted and accessible.
  Future<bool> isStorageAccessible() async {
    try {
      final path = await getStorageDirectoryPath();
      return await Directory(path).exists();
    } catch (_) {
      return false;
    }
  }

  /// Stores a file into the managed storage directory according to
  /// [ISO_DATE]_[SANITIZED_TITLE]_[UUID_SHORT].[EXTENSION]
  Future<ManagedFileInfo> storeFile({
    required File sourceFile,
    required String title,
    required DateTime documentDate,
    String? preferredExtension,
  }) async {
    final baseDir = await getStorageDirectoryPath();
    final targetDir = Directory(baseDir);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final originalExtension = preferredExtension ?? p.extension(sourceFile.path);
    final fileId = _uuid.v4();
    final managedFileName = FileSanitizer.formatManagedFileName(
      date: documentDate,
      title: title,
      uuid: fileId,
      originalExtension: originalExtension,
    );

    final destinationPath = p.join(baseDir, managedFileName);
    final copiedFile = await sourceFile.copy(destinationPath);

    final bytesHeader = await _readFirstBytes(copiedFile, 16);
    final mime = MimeDetector.detectMimeType(bytesHeader, fallbackExtension: originalExtension);
    final sha256 = await HashUtil.calculateFileSha256(copiedFile);
    final size = await copiedFile.length();

    return ManagedFileInfo(
      localFilePath: destinationPath,
      fileName: managedFileName,
      fileSizeBytes: size,
      mimeType: mime,
      sha256Hash: sha256,
    );
  }

  /// Stores raw bytes into the managed storage directory.
  Future<ManagedFileInfo> storeBytes({
    required Uint8List bytes,
    required String title,
    required DateTime documentDate,
    required String extension,
  }) async {
    final baseDir = await getStorageDirectoryPath();
    final targetDir = Directory(baseDir);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final fileId = _uuid.v4();
    final managedFileName = FileSanitizer.formatManagedFileName(
      date: documentDate,
      title: title,
      uuid: fileId,
      originalExtension: extension,
    );

    final destinationPath = p.join(baseDir, managedFileName);
    final file = File(destinationPath);
    await file.writeAsBytes(bytes, flush: true);

    final mime = MimeDetector.detectMimeType(
      bytes.sublist(0, bytes.length >= 16 ? 16 : bytes.length),
      fallbackExtension: extension,
    );
    final sha256 = HashUtil.calculateBytesSha256(bytes);

    return ManagedFileInfo(
      localFilePath: destinationPath,
      fileName: managedFileName,
      fileSizeBytes: bytes.length,
      mimeType: mime,
      sha256Hash: sha256,
    );
  }

  Future<Uint8List> _readFirstBytes(File file, int count) async {
    final raf = await file.open(mode: FileMode.read);
    try {
      return await raf.read(count);
    } finally {
      await raf.close();
    }
  }

  /// Deletes a file from the managed storage if it exists.
  Future<bool> deleteManagedFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
