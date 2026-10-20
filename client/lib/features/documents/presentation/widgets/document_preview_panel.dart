import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/file_opener_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/models/document_item.dart';
import '../../../document_reader/presentation/document_reader_screen.dart';
import '../providers/document_providers.dart';
import 'cloud_sync_settings_modal.dart';
import 'document_visuals.dart';
import 'drive_file_action_dialogs.dart';
import 'edit_document_modal.dart';
import 'sync_status_badge.dart';

class DocumentPreviewPanel extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const DocumentPreviewPanel({super.key, this.onClose});

  @override
  ConsumerState<DocumentPreviewPanel> createState() =>
      _DocumentPreviewPanelState();
}

class _DocumentPreviewPanelState extends ConsumerState<DocumentPreviewPanel> {

  /// Bounds a potentially huge string before it reaches a Text layout pass.
  /// The extracted-text field can hold megabytes (the sync schema allows up
  /// to 5M chars), and handing the whole string to TextPainter — even with
  /// maxLines + ellipsis — blocks the UI isolate and is the usual cause of
  /// the detail panel freezing on open. The full value is still stored and
  /// searchable; only this on-screen excerpt is capped.
  static String _truncateForPreview(String raw, {required int maxChars}) {
    if (raw.length <= maxChars) return raw;
    return '${raw.substring(0, maxChars)} \u2026';
  }

  /// Phase 4.3 tag chips + editor entry for the selected document.
  List<Widget> _buildTagChips(BuildContext context, WidgetRef ref, DocumentItem doc) {
    final tagIndex =
        ref.watch(documentTagIndexProvider).value ?? const <String, Set<String>>{};
    final tags = tagIndex[doc.id] ?? const <String>{};
    return [
      Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final tag in tags)
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(tag, style: const TextStyle(fontSize: 11)),
            ),
          ActionChip(
            visualDensity: VisualDensity.compact,
            avatar: const Icon(Icons.label_off_outlined, size: 14),
            label: Text(
              tags.isEmpty ? 'Pasang tag' : 'Ubah tag',
              style: const TextStyle(fontSize: 11),
            ),
            onPressed: () => _editTags(context, ref, doc),
          ),
        ],
      ),
      const SizedBox(height: AppTheme.space4),
    ];
  }

  Future<void> _editTags(
    BuildContext context,
    WidgetRef ref,
    DocumentItem doc,
  ) async {
    final tagIndex = ref.read(documentTagIndexProvider).value ??
        const <String, Set<String>>{};
    final controller = TextEditingController(
      text: (tagIndex[doc.id] ?? const <String>{}).toList().join(', '),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tag Dokumen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'pisahkan dengan koma; kosongkan untuk menghapus semua',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final names = controller.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      await ref.read(organizationRepositoryProvider).setTags(doc.id, names);
    }
    controller.dispose();
  }

  void _handleClose(BuildContext context) {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      ref.read(selectedDocumentProvider.notifier).clear();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _checkDocumentDriveStatus(
    BuildContext context,
    DocumentItem doc,
  ) async {
    CustomToast.show(
      context,
      title: 'Memeriksa Google Drive...',
      message: 'Memverifikasi status "${doc.title}"...',
      type: ToastType.info,
    );

    final newStatus = await ref
        .read(syncQueueServiceProvider)
        .checkSingleDocumentStatus(doc);

    if (context.mounted) {
      final statusMeta = DocumentVisuals.getStatusMeta(context, newStatus);
      CustomToast.show(
        context,
        title: 'Status Sinkronisasi Diperbarui',
        message: 'Status "${doc.title}": ${statusMeta.label}.',
        type: newStatus == DocumentSyncStatus.synced
            ? ToastType.success
            : ToastType.info,
      );
    }
  }

  Future<void> _uploadDocument(BuildContext context, DocumentItem doc) async {
    final cloudConfig = await ref.read(cloudConfigurationProvider.future);
    if (cloudConfig == CloudConfigurationStatus.unconfigured) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => const CloudSyncSettingsModal(promptForUpload: true),
        );
      }
      return;
    }
    if (cloudConfig == CloudConfigurationStatus.demo) {
      if (context.mounted) {
        CustomToast.show(
          context,
          title: 'Penyimpanan Offline',
          message:
              'Hubungkan akun Google Drive di Pengaturan Cloud untuk mencadangkan berkas.',
          type: ToastType.info,
        );
      }
      return;
    }

    final repo = ref.read(documentRepositoryProvider);
    final binding = await ref.read(syncAccountBindingProvider.future);
    await ref
        .read(syncQueueServiceProvider)
        .enqueueUpload(doc: doc, accountBinding: binding);
    await repo.updateSyncStatus(id: doc.id, status: DocumentSyncStatus.queued);

    if (context.mounted) {
      CustomToast.show(
        context,
        title: 'Antrean Sinkronisasi',
        message: 'Dokumen "${doc.title}" dimasukkan ke antrean sinkronisasi.',
        type: ToastType.info,
      );
    }

    unawaited(ref.read(syncQueueServiceProvider).processQueue(accountBinding: binding));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Resolve live document details or fall back to selected snapshot
    final liveDoc = ref.watch(selectedDocumentDetailsProvider);
    final fallbackDoc = ref.watch(selectedDocumentProvider);
    final doc = liveDoc ?? fallbackDoc;

    if (doc == null) {
      return Container(
        color: theme.colorScheme.surface,
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description_outlined,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: AppTheme.space16),
              Text(
                'Pilih Dokumen',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                'Pilih berkas dari daftar untuk melihat detail lengkap.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final fileMeta = DocumentVisuals.getFileIconMeta(
      doc.mimeType,
      doc.fileName,
    );
    final hasDriveFile =
        doc.gdriveFileId != null && doc.gdriveFileId!.isNotEmpty;

    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            SafeArea(
              bottom: false,
              left: false,
              right: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space20,
                  vertical: AppTheme.space16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: fileMeta.containerColor,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusControl,
                        ),
                        border: Border.all(
                          color: fileMeta.color.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          fileMeta.icon,
                          color: fileMeta.color,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doc.fileName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: DocumentVisuals.getCategoryMeta(doc.category).containerColor,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                                  border: Border.all(
                                    color: DocumentVisuals.getCategoryMeta(doc.category).color.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      DocumentVisuals.getCategoryMeta(doc.category).icon,
                                      size: 12,
                                      color: DocumentVisuals.getCategoryMeta(doc.category).color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      doc.category,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: DocumentVisuals.getCategoryMeta(doc.category).color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SyncStatusBadge(
                                status: doc.syncStatus,
                                onRetry: () => _uploadDocument(context, doc),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      tooltip: 'Tutup Detail',
                      onPressed: () => _handleClose(context),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.space20),
                children: [
                  // Action buttons: Primary Read/Open + Folder
                  Row(
                    children: [
                      if (DocumentReaderScreen.isAvailable(doc)) ...[
                        Expanded(
                          flex: 3,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.menu_book_rounded, size: 18),
                            label: const Text('Baca Dokumen'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: () =>
                                DocumentReaderScreen.open(context, doc),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: const Text('Buka Berkas'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: () => FileOpenerService.openFile(
                              doc.localFilePath,
                              context,
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.open_in_new_rounded, size: 18),
                            label: const Text('Buka Dokumen'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: () =>
                                FileOpenerService.openFile(doc.localFilePath, context),
                          ),
                        ),
                      ],
                      const SizedBox(width: AppTheme.space8),
                      IconButton.outlined(
                        tooltip: 'Buka Folder',
                        icon: const Icon(Icons.folder_open_rounded, size: 18),
                        onPressed: () => FileOpenerService.openFolder(
                          doc.localFilePath,
                          context,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space8),

                  // Metadata Actions: Edit + Favorite
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('Edit Metadata'),
                          onPressed: () =>
                              EditDocumentModal.show(context, doc),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      IconButton.filledTonal(
                        tooltip: doc.isFavorite
                            ? 'Hapus dari Favorit'
                            : 'Tandai Favorit',
                        icon: Icon(
                          doc.isFavorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: doc.isFavorite ? Colors.amber.shade700 : null,
                        ),
                        onPressed: () => ref
                            .read(documentRepositoryProvider)
                            .setFavorite(doc.id, !doc.isFavorite),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space20),

                  // Section 1: Informasi Dokumen
                  _buildSectionHeader(
                    context,
                    'Informasi Dokumen',
                    Icons.badge_rounded,
                  ),
                  const SizedBox(height: AppTheme.space8),
                  _buildInfoCard(context, [
                    if (doc.documentNumber != null &&
                        doc.documentNumber!.trim().isNotEmpty)
                      _InfoRow(
                        'Nomor Dokumen',
                        doc.documentNumber!.trim().startsWith('#') ||
                                doc.documentNumber!.trim().toLowerCase().startsWith('no')
                            ? doc.documentNumber!.trim()
                            : 'No. ${doc.documentNumber!.trim()}',
                        icon: Icons.tag_rounded,
                        isSelectable: true,
                      ),
                    _InfoRow(
                      'Kategori',
                      doc.category,
                      icon: DocumentVisuals.getCategoryMeta(doc.category).icon,
                    ),
                    _InfoRow(
                      'Tanggal Dokumen',
                      DocumentVisuals.formatFullDate(doc.documentDate),
                      icon: Icons.calendar_today_rounded,
                    ),
                    _InfoRow(
                      'Tahun Anggaran',
                      'Tahun ${doc.fiscalYear}',
                      icon: Icons.date_range_rounded,
                    ),
                    if (doc.notes != null && doc.notes!.trim().isNotEmpty)
                      _InfoRow(
                        'Catatan',
                        _truncateForPreview(doc.notes!, maxChars: 400),
                        icon: Icons.sticky_note_2_rounded,
                        isSelectable: true,
                      ),
                  ]),
                  ..._buildTagChips(context, ref, doc),
                  const SizedBox(height: AppTheme.space20),

                  // Section 2: Berkas & Cloud
                  _buildSectionHeader(
                    context,
                    'Berkas & Cloud',
                    Icons.inventory_2_rounded,
                  ),
                  const SizedBox(height: AppTheme.space8),
                  _buildInfoCard(context, [
                    _InfoRow(
                      'Format Berkas',
                      fileMeta.label,
                      icon: fileMeta.icon,
                    ),
                    _InfoRow(
                      'Ukuran Berkas',
                      DocumentVisuals.formatBytes(doc.fileSizeBytes),
                      icon: Icons.storage_rounded,
                    ),
                    _InfoRow(
                      'Terakhir Diperbarui',
                      DocumentVisuals.formatDateTime(doc.updatedAt),
                      icon: Icons.update_rounded,
                    ),
                    _InfoRow(
                      'Status Cloud',
                      DocumentVisuals.getStatusMeta(
                        context,
                        doc.syncStatus,
                      ).label,
                      icon: Icons.cloud_queue_rounded,
                    ),
                  ]),
                  if (hasDriveFile) ...[
                    const SizedBox(height: AppTheme.space12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.sync_rounded, size: 16),
                            label: const Text('Periksa Status'),
                            onPressed: () =>
                                _checkDocumentDriveStatus(context, doc),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.drive_file_rename_outline_rounded,
                              size: 16,
                            ),
                            label: const Text('Ubah Nama'),
                            onPressed: () =>
                                DriveFileActionDialogs.showRenameDialog(
                                  context: context,
                                  ref: ref,
                                  doc: doc,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppTheme.space20),

                  // Section 4: Pratinjau Teks Dokumen
                  if (doc.extractedText != null &&
                      doc.extractedText!.trim().isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      'Pratinjau Teks Dokumen',
                      Icons.article_rounded,
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusControl,
                        ),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        _truncateForPreview(
                          doc.extractedText!,
                          maxChars: 1500,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.5,
                        ),
                        maxLines: 8,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space20),
                  ],
                ],
              ),
            ),

            // Footer / Bottom Actions wrapped in SafeArea
            SafeArea(
              top: false,
              maintainBottomViewPadding: true,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: doc.syncStatus == DocumentSyncStatus.synced
                    ? OutlinedButton.icon(
                        icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                        label: const Text('Upload Ulang ke GDrive'),
                        onPressed: () => _uploadDocument(context, doc),
                      )
                    : FilledButton.icon(
                        icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                        label: const Text('Upload ke Google Drive'),
                        onPressed: () => _uploadDocument(context, doc),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: AppTheme.space8),
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, List<_InfoRow> rows) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (row.icon != null) ...[
                  Icon(row.icon, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: AppTheme.space8),
                ],
                SizedBox(
                  width: row.icon != null ? 120 : 130,
                  child: Text(
                    row.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: row.isSelectable
                      ? SelectableText(
                          row.value,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Text(
                          row.value,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final IconData? icon;
  final bool isSelectable;

  _InfoRow(this.label, this.value, {this.icon, this.isSelectable = false});
}
