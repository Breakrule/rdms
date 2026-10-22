import 'dart:io';

import '../library_backup_service.dart';

abstract interface class IBackupService {
  Future<BackupSummary> exportLibrary(Directory destinationDir);
  Future<BackupValidation> validateBackup(Directory backupDir);
  Future<RestoreSummary> restoreBackup(
    Directory backupDir, {
    required Directory rootDir,
    required ConflictPolicy policy,
  });
}
