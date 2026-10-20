import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/custom_toast.dart';
import '../../domain/models/document_item.dart';
import '../providers/document_providers.dart';

/// Modal dialogs for performing file operations directly on Google Drive (Rename & Delete).
class DriveFileActionDialogs {
  const DriveFileActionDialogs._();

  /// Prompts user to rename the document in Google Drive, with option to keep local name in sync.
  static Future<void> showRenameDialog({
    required BuildContext context,
    required WidgetRef ref,
    required DocumentItem doc,
    VoidCallback? onCompleted,
  }) async {
    final nameController = TextEditingController(text: doc.fileName);
    bool syncLocalName = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.drive_file_rename_outline_rounded,
                color: Color(0xFF0F52BA),
              ),
              SizedBox(width: 8),
              Text(
                'Ubah Nama di Google Drive',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan nama baru untuk berkas di Google Drive:',
                style: TextStyle(fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nama Berkas Cloud',
                  hintText: 'contoh.pdf',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () {
                  setState(() {
                    syncLocalName = !syncLocalName;
                  });
                },
                child: Row(
                  children: [
                    Checkbox(
                      value: syncLocalName,
                      onChanged: (val) {
                        setState(() {
                          syncLocalName = val ?? true;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Perbarui juga nama berkas lokal (agar status tetap Tersinkron)',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              if (!syncLocalName) ...[
                const SizedBox(height: 4),
                Text(
                  'Catatan: Jika nama lokal tidak disamakan, status dokumen akan menjadi "Lost".',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.deepOrange.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final newName = nameController.text.trim();
      if (newName.isEmpty || (newName == doc.fileName && syncLocalName)) return;

      CustomToast.show(
        context,
        title: 'Google Drive',
        message: 'Mengubah nama berkas di cloud...',
        type: ToastType.info,
      );

      try {
        final success = await ref
            .read(syncQueueServiceProvider)
            .renameDriveFile(
              doc: doc,
              newFileName: newName,
              updateLocalName: syncLocalName,
            );

        final updated = await ref
            .read(documentRepositoryProvider)
            .getDocumentById(doc.id);
        if (updated != null) {
          ref.read(selectedDocumentProvider.notifier).select(updated);
        }

        if (context.mounted) {
          if (success) {
            CustomToast.show(
              context,
              title: 'Nama Berhasil Diubah',
              message: syncLocalName
                  ? 'Berkas di Drive dan lokal diperbarui menjadi "$newName".'
                  : 'Berkas di Drive diubah menjadi "$newName". Status lokal menjadi Lost.',
              type: ToastType.success,
            );
            onCompleted?.call();
          } else {
            CustomToast.show(
              context,
              title: 'Gagal Mengubah Nama',
              message: 'Tidak dapat mengubah nama berkas di Google Drive.',
              type: ToastType.error,
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          CustomToast.show(
            context,
            title: 'Error Google Drive',
            message: e.toString().replaceAll('Exception: ', ''),
            type: ToastType.error,
          );
        }
      }
    }
  }

  /// Prompts user to delete or trash the document in Google Drive.
  static Future<void> showDeleteDialog({
    required BuildContext context,
    required WidgetRef ref,
    required DocumentItem doc,
    VoidCallback? onCompleted,
  }) async {
    bool moveToTrash = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Hapus dari Google Drive',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin menghapus berkas "${doc.fileName}" dari Google Drive?',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Colors.amber,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Berkas di penyimpanan lokal perangkat Anda akan tetap aman. Status dokumen akan berubah menjadi "deleted".',
                        style: TextStyle(fontSize: 11.5, color: Colors.brown),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  setState(() {
                    moveToTrash = !moveToTrash;
                  });
                },
                child: Row(
                  children: [
                    Checkbox(
                      value: moveToTrash,
                      onChanged: (val) {
                        setState(() {
                          moveToTrash = val ?? true;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Pindahkan ke Sampah (Dapat dipulihkan dari Trash Drive)',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus dari Drive'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      CustomToast.show(
        context,
        title: 'Google Drive',
        message: 'Menghapus berkas dari Google Drive...',
        type: ToastType.info,
      );

      try {
        final success = await ref
            .read(syncQueueServiceProvider)
            .deleteDriveFile(doc: doc, moveToTrash: moveToTrash);

        final updated = await ref
            .read(documentRepositoryProvider)
            .getDocumentById(doc.id);
        if (updated != null) {
          ref.read(selectedDocumentProvider.notifier).select(updated);
        }

        if (context.mounted) {
          if (success) {
            CustomToast.show(
              context,
              title: 'Berkas Cloud Dihapus',
              message: moveToTrash
                  ? 'Berkas dipindahkan ke Sampah Google Drive. Status menjadi "deleted".'
                  : 'Berkas dihapus permanen dari Google Drive. Status menjadi "deleted".',
              type: ToastType.warning,
            );
            onCompleted?.call();
          } else {
            CustomToast.show(
              context,
              title: 'Gagal Menghapus',
              message: 'Tidak dapat menghapus berkas dari Google Drive.',
              type: ToastType.error,
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          CustomToast.show(
            context,
            title: 'Error Google Drive',
            message: e.toString().replaceAll('Exception: ', ''),
            type: ToastType.error,
          );
        }
      }
    }
  }
}
