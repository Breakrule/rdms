import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/models/document_item.dart';
import '../providers/document_providers.dart';

/// Phase 4.6: the action bar states the exact count and names scope,
/// and every action operates on [selectedDocumentsProvider] (live
/// documents, not stale ids).
class MultiSelectActionBar extends ConsumerWidget {
  final List<DocumentItem> documents;

  const MultiSelectActionBar({super.key, required this.documents});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space4,
          ),
          child: Row(
            children: [
              Icon(
                Icons.checklist_rounded,
                size: 18,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                child: Text(
                  '${documents.length} dokumen terpilih',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.label_outline_rounded, size: 16),
                label: const Text('Tag'),
                onPressed: () => _applyTag(context, ref),
              ),
              TextButton.icon(
                icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                label: const Text('Cadangkan'),
                onPressed: () => _queueBackup(context, ref),
              ),
              TextButton.icon(
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Ekspor Berkas'),
                onPressed: () => _exportFiles(context, ref),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Ke Sampah'),
                onPressed: () => _moveToTrash(context, ref),
              ),
              IconButton(
                tooltip: 'Batal pilih',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () =>
                    ref.read(documentSelectionProvider.notifier).clear(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyTag(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pasang tag ke ${documents.length} dokumen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Nama tag'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pasang'),
          ),
        ],
      ),
    );
    final name = controller.text.trim().toLowerCase();
    controller.dispose();
    if (confirmed != true || name.isEmpty || !context.mounted) return;
    await ref.read(organizationRepositoryProvider).addTagToDocuments(
          name,
          documents.map((d) => d.id).toList(),
        );
    if (context.mounted) {
      CustomToast.show(
        context,
        title: 'Tag dipasang',
        message: '"$name" ditambahkan ke ${documents.length} dokumen.',
        type: ToastType.success,
      );
    }
  }

  Future<void> _queueBackup(BuildContext context, WidgetRef ref) async {
    final binding = await ref.read(syncAccountBindingProvider.future);
    final queue = ref.read(syncQueueServiceProvider);
    var count = 0;
    for (final d in documents) {
      if (d.syncStatus == DocumentSyncStatus.localOnly ||
          d.syncStatus == DocumentSyncStatus.error) {
        await queue.enqueueUpload(doc: d, accountBinding: binding);
        count++;
      }
    }
    if (context.mounted) {
      CustomToast.show(
        context,
        title: 'Antrean Cadangan',
        message: '$count dari ${documents.length} dokumen diantrekan.',
        type: ToastType.info,
      );
    }
    unawaited(queue.processQueue(accountBinding: binding));
  }

  Future<void> _exportFiles(BuildContext context, WidgetRef ref) async {
    final dir = await FilePicker.getDirectoryPath(
      dialogTitle: 'Tujuan ekspor berkas terpilih',
    );
    if (dir == null || !context.mounted) return;
    final summary = await ref
        .read(documentExportServiceProvider)
        .exportFiles(destination: Directory(dir), documents: documents);
    if (context.mounted) {
      CustomToast.show(
        context,
        title: 'Ekspor Berkas',
        message:
            '${summary.copied} disalin, ${summary.missing} tidak ditemukan.',
        type: summary.missing == 0 ? ToastType.success : ToastType.warning,
      );
    }
  }

  Future<void> _moveToTrash(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pindahkan ke Tempat Sampah?'),
        content: Text(
          '${documents.length} dokumen akan dipindahkan ke tempat sampah lokal '
          'dan tetap bisa dipulihkan. Salinan Google Drive tidak terpengaruh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pindahkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final repo = ref.read(documentRepositoryProvider);
    for (final d in documents) {
      await repo.trashDocument(d.id);
    }
    final currentSelected = ref.read(selectedDocumentProvider);
    if (currentSelected != null &&
        documents.any((d) => d.id == currentSelected.id)) {
      ref.read(selectedDocumentProvider.notifier).clear();
    }
    ref.read(documentSelectionProvider.notifier).clear();
    if (context.mounted) {
      CustomToast.show(
        context,
        title: 'Dipindahkan ke Tempat Sampah',
        message:
            '${documents.length} dokumen bisa dipulihkan dari Pulihkan & Backup.',
        type: ToastType.info,
      );
    }
  }
}
