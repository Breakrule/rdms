import '../../../features/documents/domain/models/document_item.dart';
import '../sync_queue_service.dart';

abstract interface class ISyncService {
  Stream<SyncProgressState> get progressStream;
  void pause();
  void resume();
  void dispose();
  Future<void> enqueueUpload({
    required DocumentItem doc,
    required String accountBinding,
  });
  Future<void> enqueueMetadataOnly({
    required DocumentItem doc,
    required String accountBinding,
  });
  Future<void> processQueue({
    required String accountBinding,
  });
  Future<bool> syncSingleDocument(
    DocumentItem doc, {
    required String accountBinding,
  });
  Future<DocumentSyncStatus> checkSingleDocumentStatus(DocumentItem doc);
  Future<SyncRollup> reconcileAllDocuments();
  Future<bool> renameDriveFile({
    required DocumentItem doc,
    required String newFileName,
    required bool updateLocalName,
  });
  Future<bool> deleteDriveFile({
    required DocumentItem doc,
    bool moveToTrash = true,
  });
  Future<int> enqueueAllUnsynced({
    required String accountBinding,
  });
}
