import 'dart:io';
import 'dart:typed_data';

import '../storage_service.dart';

abstract interface class IStorageService {
  Future<void> setCustomBasePath(String path);
  Future<String> getStorageDirectoryPath();
  Future<bool> isStorageAccessible();
  Future<ManagedFileInfo> storeFile({
    required File sourceFile,
    required String title,
    required DateTime documentDate,
    String? preferredExtension,
  });
  Future<ManagedFileInfo> storeBytes({
    required Uint8List bytes,
    required String title,
    required DateTime documentDate,
    required String extension,
  });
  Future<bool> deleteManagedFile(String path);
}
