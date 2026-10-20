import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'drive_upload_session_repository.dart';
import 'token_storage_service.dart';
import 'google_auth_service.dart';

enum GDriveFileCheckStatus {
  synced,
  deleted,
  lost,
  unreachable,
}

class GDriveFileCheckResult {
  final GDriveFileCheckStatus status;
  final String? driveFileName;
  final String? message;

  const GDriveFileCheckResult({
    required this.status,
    this.driveFileName,
    this.message,
  });
}

class GDriveUploadResult {
  final String fileId;
  final String fileName;
  final int bytesUploaded;
  final bool isResumed;
  final String targetFolder;

  const GDriveUploadResult({
    required this.fileId,
    required this.fileName,
    required this.bytesUploaded,
    this.isResumed = false,
    this.targetFolder = 'RDMS Documents',
  });
}

/// Auth failure that will not resolve by retrying (401, missing token,
/// scope revoked). Phase 2.3 blocks the job until the user reconnects.
class GDriveAuthException implements Exception {
  final String redactedMessage;
  GDriveAuthException(this.redactedMessage);
  @override
  String toString() => 'GDriveAuthException: $redactedMessage';
}

/// Transient failure (network, 429, 5xx, expired session URI). The
/// queue retries with backoff (Phase 2.3).
class GDriveTransientException implements Exception {
  final String redactedMessage;
  GDriveTransientException(this.redactedMessage);
  @override
  String toString() => 'GDriveTransientException: $redactedMessage';
}

/// Service handling Google Drive v3 resumable + direct upload.
///
/// Phase 2 changes (implementation_plan_feat.md 2.4 / 2.5):
/// - [uploadFileResumable] persists the session URI + acknowledged byte
///   offset via [DriveUploadSessionRepository], so a process restart
///   resumes at the last byte Google confirmed rather than re-uploading
///   from zero.
/// - Uploads stamp the document UUID and job UUID into Drive
///   `appProperties`, which lets us detect "the previous attempt
///   completed but we crashed before saving fileId" and reuse the
///   remote object instead of creating a duplicate.
/// - Chunked Range uploads send a bounded 8 MiB window per request
///   (aligned to Drive's 256 KiB multiple requirement) so a slow link
///   does not time out the whole file.
///
/// Real resumable behaviour is verified against a live Drive in Phase
/// 9 CI; the pipeline here is exercised in tests via a mock Dio.
class GDriveService {
  final Dio _dio;
  final TokenStorageService _tokenStorage;
  final GoogleAuthService? googleAuthService;
  final DriveUploadSessionRepository? sessionRepository;
  final bool mockMode;

  /// Drive requires each chunk (except the last) to be a multiple of
  /// 256 KiB. 8 MiB is a good trade between progress granularity and
  /// request overhead.
  static const int chunkSize = 8 * 1024 * 1024;

  GDriveService({
    Dio? dio,
    TokenStorageService? tokenStorage,
    this.googleAuthService,
    this.sessionRepository,
    this.mockMode = false,
  })  : _dio = dio ?? Dio(),
        _tokenStorage = tokenStorage ?? TokenStorageService();

  Future<String?> _resolveToken() async {
    String? token = await googleAuthService?.getValidAccessToken();
    token ??= await _tokenStorage.getAccessToken();
    return token;
  }

  Future<String?> _getOrCreateFolder({
    required String folderName,
    required String token,
  }) async {
    try {
      final query =
          "name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      final searchRes = await _dio.get(
        'https://www.googleapis.com/drive/v3/files',
        queryParameters: {
          'q': query,
          'fields': 'files(id, name)',
          'spaces': 'drive',
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final files = searchRes.data['files'] as List<dynamic>?;
      if (files != null && files.isNotEmpty) {
        return files.first['id'] as String;
      }

      final createRes = await _dio.post(
        'https://www.googleapis.com/drive/v3/files',
        data: {
          'name': folderName,
          'mimeType': 'application/vnd.google-apps.folder',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );
      return createRes.data['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<GDriveFileCheckResult> checkFileStatus({
    required String fileId,
    required String expectedFileName,
  }) async {
    if (mockMode) {
      if (fileId.contains('deleted')) {
        return const GDriveFileCheckResult(
          status: GDriveFileCheckStatus.deleted,
          message: 'Berkas tidak dapat diakses di Google Drive.',
        );
      }
      if (fileId.contains('lost')) {
        return const GDriveFileCheckResult(
          status: GDriveFileCheckStatus.lost,
          driveFileName: 'modified_on_drive.pdf',
          message: 'Nama berkas di Google Drive telah berubah.',
        );
      }
      return const GDriveFileCheckResult(status: GDriveFileCheckStatus.synced);
    }

    final token = await _resolveToken();
    if (token == null || token.trim().isEmpty) {
      return const GDriveFileCheckResult(
        status: GDriveFileCheckStatus.unreachable,
        message: 'Akun Google Drive belum terhubung.',
      );
    }

    try {
      final res = await _dio.get(
        'https://www.googleapis.com/drive/v3/files/$fileId',
        queryParameters: {
          'fields': 'id,name,trashed',
          'supportsAllDrives': true,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final isTrashed = res.data['trashed'] == true;
      if (isTrashed) {
        return const GDriveFileCheckResult(
          status: GDriveFileCheckStatus.deleted,
          message: 'Berkas berada di Sampah (Trash) Google Drive.',
        );
      }
      final driveName = res.data['name'] as String?;
      if (driveName != null && driveName != expectedFileName) {
        return GDriveFileCheckResult(
          status: GDriveFileCheckStatus.lost,
          driveFileName: driveName,
          message: 'Nama berkas di Google Drive diubah menjadi: "$driveName"',
        );
      }
      return const GDriveFileCheckResult(status: GDriveFileCheckStatus.synced);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const GDriveFileCheckResult(
          status: GDriveFileCheckStatus.deleted,
          message: 'Berkas tidak ditemukan atau telah dihapus di Google Drive.',
        );
      }
      return GDriveFileCheckResult(
        status: GDriveFileCheckStatus.unreachable,
        message: 'Gagal menghubungi Google Drive: ${e.message}',
      );
    } catch (e) {
      return GDriveFileCheckResult(
        status: GDriveFileCheckStatus.unreachable,
        message: 'Error saat memeriksa status: $e',
      );
    }
  }

  /// Legacy upload entry point kept so existing UI continues to work.
  /// New code paths should call [uploadFileResumable] with a jobId so
  /// the session is persisted for cross-restart resume.
  Future<GDriveUploadResult> uploadFile({
    required File file,
    required String fileName,
    required String mimeType,
    required String title,
    String? customFolderName,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (mockMode) {
      final size = await file.length();
      if (onProgress != null) onProgress(size, size);
      final simulatedId = 'gdrive_${fileName.hashCode.abs().toRadixString(16)}';
      return GDriveUploadResult(
        fileId: simulatedId,
        fileName: fileName,
        bytesUploaded: size,
        targetFolder: customFolderName ?? 'RDMS Documents',
      );
    }
    final binding = await _resolveAccountBinding();
    return uploadFileResumable(
      file: file,
      fileName: fileName,
      mimeType: mimeType,
      title: title,
      jobId: 'legacy-$fileName-${DateTime.now().microsecondsSinceEpoch}',
      documentId: binding,
      customFolderName: customFolderName,
      onProgress: onProgress,
    );
  }

  Future<String> _resolveAccountBinding() async {
    final user = googleAuthService?.currentUser;
    return user?.id ?? 'local-device';
  }

  /// Phase 2.4 + 2.5. Resumable upload with:
  /// - Persisted session URI + acknowledged offset (via
  ///   [DriveUploadSessionRepository] when supplied)
  /// - `appProperties` stamp (documentUuid + jobId) so a re-run can
  ///   discover the previous remote object instead of uploading twice
  /// - Chunked Range PUT aligned to Drive's 256 KiB multiple
  /// - 308 handling to query an in-flight session's offset on resume
  /// - Explicit auth vs transient failure classification so the queue
  ///   can decide between `blocked` and `retryableFailure`
  Future<GDriveUploadResult> uploadFileResumable({
    required File file,
    required String fileName,
    required String mimeType,
    required String title,
    required String jobId,
    required String documentId,
    String? customFolderName,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (mockMode) {
      final size = await file.length();
      if (onProgress != null) onProgress(size, size);
      final simulatedId = 'gdrive_${fileName.hashCode.abs().toRadixString(16)}';
      return GDriveUploadResult(
        fileId: simulatedId,
        fileName: fileName,
        bytesUploaded: size,
        isResumed: false,
        targetFolder: customFolderName ?? 'RDMS Documents',
      );
    }

    if (await _tokenStorage.isDemoMode()) {
      throw GDriveAuthException(
        'Mode Simulasi Cloud aktif. Hubungkan akun Google untuk mengunggah.',
      );
    }
    final token = await _resolveToken();
    if (token == null || token.trim().isEmpty) {
      throw GDriveAuthException('Akun Google Drive belum terhubung.');
    }

    // 2.5 duplicate prevention: check for an existing remote file with
    // the same appProperties BEFORE starting a new session.
    final existing = await _findExistingByAppProperties(
      token: token,
      documentId: documentId,
      jobId: jobId,
    );
    if (existing != null) {
      // The prior run completed but the client crashed before saving
      // fileId. Adopt the existing object.
      return GDriveUploadResult(
        fileId: existing,
        fileName: fileName,
        bytesUploaded: await file.length(),
        isResumed: true,
      );
    }

    final fileSize = await file.length();
    final targetFolder = customFolderName ?? await _tokenStorage.getTargetFolderName();
    String? folderId;
    if (targetFolder.trim().isNotEmpty) {
      folderId = await _getOrCreateFolder(folderName: targetFolder.trim(), token: token);
      if (folderId == null) {
        throw GDriveTransientException(
          'Tidak dapat resolve folder "$targetFolder"; upload dibatalkan untuk hindari duplikat di root.',
        );
      }
    }

    // Try to pick up an open session for this job.
    final repo = sessionRepository;
    final prior = repo == null ? null : await repo.forJob(jobId);
    String sessionUri;
    int offset = 0;
    bool isResumed = false;

    if (prior != null) {
      // Query the session URI to reconcile what Drive actually has.
      final reconciled = await _querySessionOffset(prior.sessionUri, token);
      if (reconciled == null) {
        // Session expired (410/404). Start fresh.
        await repo?.markExpired(prior.id);
        sessionUri = await _initiateSession(
          token: token,
          fileName: fileName,
          mimeType: mimeType,
          title: title,
          fileSize: fileSize,
          folderId: folderId,
          documentId: documentId,
          jobId: jobId,
        );
        if (repo != null) {
          await repo.create(
            jobId: jobId,
            documentId: documentId,
            sessionUri: sessionUri,
            totalBytes: fileSize,
          );
        }
      } else {
        sessionUri = prior.sessionUri;
        offset = reconciled;
        isResumed = true;
      }
    } else {
      sessionUri = await _initiateSession(
        token: token,
        fileName: fileName,
        mimeType: mimeType,
        title: title,
        fileSize: fileSize,
        folderId: folderId,
        documentId: documentId,
        jobId: jobId,
      );
      if (repo != null) {
        await repo.create(
          jobId: jobId,
          documentId: documentId,
          sessionUri: sessionUri,
          totalBytes: fileSize,
        );
      }
    }

    final sessionIdForUpdate = repo == null ? null : (prior?.id ?? await _lookupSessionId(repo, jobId));
    final fileId = await _sendChunks(
      file: file,
      fileSize: fileSize,
      startOffset: offset,
      sessionUri: sessionUri,
      token: token,
      onProgress: onProgress,
      onAcked: sessionIdForUpdate != null
          ? (acked) => repo!.advance(id: sessionIdForUpdate, bytesAcknowledged: acked)
          : null,
    );

    if (repo != null && sessionIdForUpdate != null) {
      await repo.markComplete(sessionIdForUpdate);
    }

    return GDriveUploadResult(
      fileId: fileId,
      fileName: fileName,
      bytesUploaded: fileSize,
      isResumed: isResumed,
      targetFolder: targetFolder,
    );
  }

  Future<String?> _lookupSessionId(DriveUploadSessionRepository repo, String jobId) async {
    final row = await repo.forJob(jobId);
    return row?.id;
  }

  Future<String?> _findExistingByAppProperties({
    required String token,
    required String documentId,
    required String jobId,
  }) async {
    try {
      final q = "appProperties has { documentUuid='$documentId' and jobId='$jobId' } and trashed = false";
      final res = await _dio.get(
        'https://www.googleapis.com/drive/v3/files',
        queryParameters: {
          'q': q,
          'fields': 'files(id, name)',
          'spaces': 'drive',
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final files = (res.data['files'] as List<dynamic>?) ?? const [];
      if (files.isEmpty) return null;
      return files.first['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String> _initiateSession({
    required String token,
    required String fileName,
    required String mimeType,
    required String title,
    required int fileSize,
    required String? folderId,
    required String documentId,
    required String jobId,
  }) async {
    final metadata = <String, dynamic>{
      'name': fileName,
      'description': title,
      // Phase 2.5 dedup key. Drive allows 10 properties on files created
      // by the app; we use two.
      'appProperties': {
        'documentUuid': documentId,
        'jobId': jobId,
      },
    };
    if (folderId != null) metadata['parents'] = [folderId];

    try {
      final initRes = await _dio.post(
        'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable',
        data: metadata,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-Upload-Content-Type': mimeType,
            'X-Upload-Content-Length': fileSize.toString(),
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );
      final uri = initRes.headers.value('location');
      if (uri == null || uri.isEmpty) {
        throw GDriveTransientException('Gagal mendapatkan sesi upload Google Drive.');
      }
      return uri;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw GDriveAuthException('Sesi upload ditolak (${e.response?.statusCode}).');
      }
      throw GDriveTransientException('Gagal memulai sesi upload: ${e.message}');
    }
  }

  /// Queries the session URI (a PUT with `Content-Range: bytes */<size>`)
  /// to see the current byte offset Drive has accepted. Returns the
  /// offset (0 if nothing received yet) or null if the session is
  /// expired/unknown (410/404).
  Future<int?> _querySessionOffset(String sessionUri, String token) async {
    try {
      final res = await _dio.put(
        sessionUri,
        data: Uint8List(0),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Length': '0',
            'Content-Range': 'bytes */0',
          },
          validateStatus: (s) => s != null && (s < 500),
        ),
      );
      if (res.statusCode == 410 || res.statusCode == 404) return null;
      final range = res.headers.value('range');
      if (range == null) return 0;
      final match = RegExp(r'bytes=0-(\d+)').firstMatch(range);
      if (match == null) return 0;
      return int.parse(match.group(1)!) + 1;
    } catch (_) {
      return null;
    }
  }

  Future<String> _sendChunks({
    required File file,
    required int fileSize,
    required int startOffset,
    required String sessionUri,
    required String token,
    required void Function(int sent, int total)? onProgress,
    required Future<void> Function(int acked)? onAcked,
  }) async {
    final raf = await file.open(mode: FileMode.read);
    try {
      var offset = startOffset;
      while (offset < fileSize) {
        final remaining = fileSize - offset;
        final chunkLen = remaining > chunkSize ? chunkSize : remaining;
        await raf.setPosition(offset);
        final chunkBytes = await raf.read(chunkLen);
        final endInclusive = offset + chunkBytes.length - 1;

        Response<dynamic> res;
        try {
          res = await _dio.put(
            sessionUri,
            data: chunkBytes,
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Length': chunkBytes.length.toString(),
                'Content-Range': 'bytes $offset-$endInclusive/$fileSize',
              },
              validateStatus: (s) => s != null && s < 500,
            ),
          );
        } on DioException catch (e) {
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            throw GDriveAuthException('Sesi upload ditolak saat kirim chunk.');
          }
          throw GDriveTransientException('Chunk upload gagal: ${e.message}');
        }

        final status = res.statusCode ?? 0;
        if (status == 308) {
          // Partial: server tells us the range it received.
          final range = res.headers.value('range');
          if (range != null) {
            final match = RegExp(r'bytes=0-(\d+)').firstMatch(range);
            if (match != null) {
              offset = int.parse(match.group(1)!) + 1;
              if (onAcked != null) await onAcked(offset);
              if (onProgress != null) onProgress(offset, fileSize);
              continue;
            }
          }
          // No Range header: keep position, retry next chunk boundary.
          if (onProgress != null) onProgress(offset, fileSize);
          continue;
        }
        if (status == 200 || status == 201) {
          if (onProgress != null) onProgress(fileSize, fileSize);
          final data = res.data;
          if (data is Map<String, dynamic> && data['id'] is String) {
            return data['id'] as String;
          }
          throw GDriveTransientException(
            'Sesi upload selesai tetapi response tidak memuat fileId.',
          );
        }
        if (status == 410 || status == 404) {
          throw GDriveTransientException('Sesi upload kadaluarsa; coba ulangi.');
        }
        if (status == 401 || status == 403) {
          throw GDriveAuthException('Ditolak oleh Google Drive ($status).');
        }
        if (status == 429 || status >= 500) {
          throw GDriveTransientException('Google Drive sibuk ($status).');
        }
        throw GDriveTransientException('Kode tak terduga $status saat upload chunk.');
      }
      throw GDriveTransientException('Loop upload selesai tanpa 200/201 response.');
    } finally {
      await raf.close();
    }
  }

  Future<bool> renameFile({
    required String fileId,
    required String newFileName,
  }) async {
    if (mockMode) return true;
    final token = await _resolveToken();
    if (token == null || token.trim().isEmpty) {
      throw GDriveAuthException('Akun Google Drive belum terhubung.');
    }
    try {
      final res = await _dio.patch(
        'https://www.googleapis.com/drive/v3/files/$fileId',
        queryParameters: {'supportsAllDrives': true},
        data: {'name': newFileName},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return res.statusCode == 200;
    } on DioException catch (e) {
      throw GDriveTransientException('Gagal mengubah nama berkas: ${e.message}');
    }
  }

  Future<bool> deleteFile({
    required String fileId,
    bool moveToTrash = true,
  }) async {
    if (mockMode) return true;
    final token = await _resolveToken();
    if (token == null || token.trim().isEmpty) {
      throw GDriveAuthException('Akun Google Drive belum terhubung.');
    }
    try {
      if (moveToTrash) {
        final res = await _dio.patch(
          'https://www.googleapis.com/drive/v3/files/$fileId',
          queryParameters: {'supportsAllDrives': true},
          data: {'trashed': true},
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        return res.statusCode == 200;
      } else {
        final res = await _dio.delete(
          'https://www.googleapis.com/drive/v3/files/$fileId',
          queryParameters: {'supportsAllDrives': true},
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        return res.statusCode == 204 || res.statusCode == 200;
      }
    } on DioException catch (e) {
      throw GDriveTransientException('Gagal menghapus: ${e.message}');
    }
  }
}
