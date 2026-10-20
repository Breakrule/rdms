import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../features/documents/domain/models/document_item.dart';
import 'token_storage_service.dart';

class BackendBatchSyncResult {
  final bool success;
  final int totalReceived;
  final int inserted;
  final int updated;

  const BackendBatchSyncResult({
    required this.success,
    required this.totalReceived,
    required this.inserted,
    required this.updated,
  });
}

class BackendReconcileResult {
  final List<String> missingOnServer;
  final List<String> outdatedOnServer;
  final int syncedCount;

  const BackendReconcileResult({
    required this.missingOnServer,
    required this.outdatedOnServer,
    required this.syncedCount,
  });
}

/// Per-operation outcome from the v2 batch endpoint (Phase 2.6).
class BackendSyncOperationResult {
  final String operationId;
  final String outcome; // applied | conflict | rejected
  final String? serverDocumentId;
  final int revisionAfter;
  final String? errorCode;

  const BackendSyncOperationResult({
    required this.operationId,
    required this.outcome,
    required this.serverDocumentId,
    required this.revisionAfter,
    this.errorCode,
  });
}

class BackendSyncBatchResult {
  final bool success;
  final int totalReceived;
  final List<BackendSyncOperationResult> results;

  const BackendSyncBatchResult({
    required this.success,
    required this.totalReceived,
    required this.results,
  });
}

/// Transient backend failure (network, 5xx, request timeout). The sync
/// queue retries with backoff. Distinct from permanent failures so we
/// stop retrying an operation the server has explicitly rejected.
class BackendTransientException implements Exception {
  final String message;
  BackendTransientException(this.message);
  @override
  String toString() => 'BackendTransientException: $message';
}

/// Client for communicating with the Node.js DMS Metadata API.
///
/// v1 endpoints (`/sync/batch-metadata`, `/sync/reconcile`) stay for
/// legacy compatibility during the migration window. New write paths
/// should use [applyOperations] which hits `/api/v2/sync/batch` and
/// gets per-operation results with revision acknowledgements.
class BackendSyncClient {
  final Dio _dio;
  final TokenStorageService _tokenStorage;
  final String? _explicitBaseUrl;

  BackendSyncClient({
    Dio? dio,
    TokenStorageService? tokenStorage,
    String? baseUrl,
  })  : _dio = dio ?? Dio(),
        _tokenStorage = tokenStorage ?? TokenStorageService(),
        _explicitBaseUrl = baseUrl;

  Future<String> _getBaseUrl() async {
    if (_explicitBaseUrl != null) return _explicitBaseUrl;
    try {
      return await _tokenStorage.getBackendBaseUrl();
    } catch (_) {
      return 'http://127.0.0.1:4000';
    }
  }

  /// Sends a batch of document metadata to POST /api/v1/sync/batch-metadata.
  /// Deprecated for new writes; kept for the migration window.
  Future<BackendBatchSyncResult> syncBatchMetadata(List<DocumentItem> documents) async {
    final baseUrl = await _getBaseUrl();
    final dateFormat = DateFormat('yyyy-MM-dd');

    final payload = documents.map((doc) {
      return {
        'clientLocalId': doc.id,
        'title': doc.title,
        'documentNumber': doc.documentNumber,
        'categoryCode': doc.category,
        'documentDate': dateFormat.format(doc.documentDate),
        'fiscalYear': doc.fiscalYear,
        'fileName': doc.fileName,
        'fileSizeBytes': doc.fileSizeBytes,
        'mimeType': doc.mimeType,
        'sha256Hash': doc.sha256Hash,
        'gdriveFileId': doc.gdriveFileId,
        'extractedText': doc.extractedText,
        // Absolute local paths are Phase 0.4/1.6 privacy leak; do NOT
        // include them in the payload.
        'customMetadata': <String, dynamic>{},
      };
    }).toList();

    final res = await _dio.post(
      '$baseUrl/api/v1/sync/batch-metadata',
      data: {'documents': payload},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    final data = res.data['data'] as Map<String, dynamic>;
    return BackendBatchSyncResult(
      success: data['success'] as bool? ?? true,
      totalReceived: data['totalReceived'] as int? ?? documents.length,
      inserted: data['inserted'] as int? ?? 0,
      updated: data['updated'] as int? ?? 0,
    );
  }

  Future<BackendReconcileResult> reconcile(List<DocumentItem> documents) async {
    final baseUrl = await _getBaseUrl();
    final items = documents.map((doc) {
      return {
        'clientLocalId': doc.id,
        'sha256Hash': doc.sha256Hash,
      };
    }).toList();

    final res = await _dio.post(
      '$baseUrl/api/v1/sync/reconcile',
      data: {'items': items},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    final data = res.data['data'] as Map<String, dynamic>;
    return BackendReconcileResult(
      missingOnServer: List<String>.from(data['missingOnServer'] ?? []),
      outdatedOnServer: List<String>.from(data['outdatedOnServer'] ?? []),
      syncedCount: data['syncedCount'] as int? ?? 0,
    );
  }

  /// POST /api/v2/sync/batch.
  ///
  /// Each operation carries its own idempotency key and baseRevision so
  /// a network retry returns the ORIGINAL outcome and a stale client
  /// cannot silently overwrite newer server data. Transient failures
  /// throw [BackendTransientException] so the queue can back off; the
  /// caller inspects per-op `outcome` for applied/conflict/rejected.
  Future<BackendSyncBatchResult> applyOperations(
    List<Map<String, dynamic>> operations,
  ) async {
    final baseUrl = await _getBaseUrl();
    Response<dynamic> res;
    try {
      res = await _dio.post(
        '$baseUrl/api/v2/sync/batch',
        data: {'operations': operations},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } on DioException catch (e) {
      throw BackendTransientException(_describeDio(e));
    }

    final body = res.data;
    if (body is! Map) {
      throw BackendTransientException('Response body bukan JSON object.');
    }
    final data = body['data'];
    if (data is! Map) {
      throw BackendTransientException('Response data field hilang.');
    }
    final rawResults = (data['results'] as List?) ?? const [];
    return BackendSyncBatchResult(
      success: data['success'] as bool? ?? true,
      totalReceived: data['totalReceived'] as int? ?? rawResults.length,
      results: rawResults
          .map((r) => BackendSyncOperationResult(
                operationId: r['operationId'] as String,
                outcome: r['outcome'] as String,
                serverDocumentId: r['serverDocumentId'] as String?,
                revisionAfter: (r['revisionAfter'] as num).toInt(),
                errorCode: r['errorCode'] as String?,
              ))
          .toList(),
    );
  }

  String _describeDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Backend timeout (${e.type.name})';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        if (status >= 500 || status == 429) return 'Backend $status';
        return 'Backend error $status';
      case DioExceptionType.cancel:
        return 'Cancelled';
      default:
        return 'Backend unreachable: ${e.message ?? e.type.name}';
    }
  }
}
