import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/file_opener_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/models/document_item.dart';
import '../providers/document_providers.dart';
import 'document_visuals.dart';
import 'drive_file_action_dialogs.dart';
import 'sync_status_badge.dart';

class DocumentListItem extends ConsumerStatefulWidget {
  final DocumentItem doc;
  final bool isSelected;
  final bool isStacked;
  final void Function(DocumentItem doc) onSelect;

  const DocumentListItem({
    super.key,
    required this.doc,
    required this.isSelected,
    required this.isStacked,
    required this.onSelect,
  });

  @override
  ConsumerState<DocumentListItem> createState() => _DocumentListItemState();
}

class _DocumentListItemState extends ConsumerState<DocumentListItem> {
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _menuKey = GlobalKey();
  bool _isHovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRetrySync() async {
    final cloudConfig = await ref.read(cloudConfigurationProvider.future);
    if (cloudConfig == CloudConfigurationStatus.unconfigured) {
      if (mounted) {
        CustomToast.show(
          context,
          title: 'Google Drive Belum Dikonfigurasi',
          message: 'Silakan atur kredensial Google Drive terlebih dahulu.',
          type: ToastType.warning,
        );
      }
      return;
    }
    if (cloudConfig == CloudConfigurationStatus.demo) {
      if (mounted) {
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
        .enqueueUpload(doc: widget.doc, accountBinding: binding);
    // Keep legacy status update so the badge reflects "queued" until the
    // worker advances replica state.
    await repo.updateSyncStatus(
      id: widget.doc.id,
      status: DocumentSyncStatus.queued,
    );

    // Run queue in background
    unawaited(ref.read(syncQueueServiceProvider).processQueue(accountBinding: binding));
  }

  Future<void> _handleLocalDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pindahkan ke Tempat Sampah'),
        content: Text(
          'Pindahkan "${widget.doc.title}" ke tempat sampah lokal?\n\n'
          'Berkas tetap tersimpan di perangkat Anda dan bisa dipulihkan '
          'dari Pulihkan & Backup. Salinan di Google Drive (jika ada) tidak '
          'akan terpengaruh.',
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

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(documentRepositoryProvider)
            .trashDocument(widget.doc.id);
        final currentlySelected = ref.read(selectedDocumentProvider);
        if (currentlySelected?.id == widget.doc.id) {
          ref.read(selectedDocumentProvider.notifier).clear();
        }
        if (mounted) {
          CustomToast.show(
            context,
            title: 'Dipindahkan ke Tempat Sampah',
            message:
                '"${widget.doc.title}" bisa dipulihkan dari menu Pulihkan & Backup.',
            type: ToastType.info,
          );
        }
      } catch (e) {
        if (mounted) {
          CustomToast.show(
            context,
            title: 'Gagal Memindahkan',
            message: 'Terjadi kesalahan saat memindahkan dokumen: $e',
            type: ToastType.error,
          );
        }
      }
    }
  }

  void _openPopupMenu() {
    dynamic state = _menuKey.currentState;
    state?.showButtonMenu();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doc = widget.doc;
    final fileMeta = DocumentVisuals.getFileIconMeta(
      doc.mimeType,
      doc.fileName,
    );
    final catMeta = DocumentVisuals.getCategoryMeta(doc.category);
    final inBatch = ref.watch(
      documentSelectionProvider.select((s) => s.contains(doc.id)),
    );

    return Dismissible(
      key: ValueKey('dismiss_doc_${doc.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
        color: Theme.of(context).colorScheme.error,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Tempat Sampah',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            SizedBox(width: AppTheme.space8),
            Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Pindahkan ke Tempat Sampah'),
            content: Text(
              'Pindahkan "${doc.title}" ke tempat sampah lokal?\n\n'
              'Berkas tetap tersimpan di perangkat Anda dan bisa dipulihkan '
              'dari Pulihkan & Backup.',
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
      },
      onDismissed: (direction) async {
        await ref.read(documentRepositoryProvider).trashDocument(doc.id);
        final currentlySelected = ref.read(selectedDocumentProvider);
        if (currentlySelected?.id == doc.id) {
          ref.read(selectedDocumentProvider.notifier).clear();
        }
        if (context.mounted) {
          CustomToast.show(
            context,
            title: 'Dipindahkan ke Tempat Sampah',
            message: '"${doc.title}" bisa dipulihkan dari menu Pulihkan & Backup.',
            type: ToastType.info,
          );
        }
      },
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter) {
              widget.onSelect(doc);
              return KeyEventResult.handled;
            }
            if (HardwareKeyboard.instance.isShiftPressed &&
                event.logicalKey == LogicalKeyboardKey.f10) {
              _openPopupMenu();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: InkWell(
            onTap: () {
              // Long-press-free batch mode: while a selection is active,
              // taps toggle membership instead of opening details
              // (Phase 4.6). A tap on the only remaining row's details
              // is still available via the action bar's clear button.
              final selectionActive = ref
                  .read(documentSelectionProvider)
                  .isNotEmpty;
              if (selectionActive) {
                ref.read(documentSelectionProvider.notifier).toggle(doc.id);
              } else {
                widget.onSelect(doc);
              }
            },
            onLongPress: () =>
                ref.read(documentSelectionProvider.notifier).toggle(doc.id),
            onDoubleTap: () =>
                FileOpenerService.openFile(doc.localFilePath, context),
            child: AnimatedContainer(
              duration: AppTheme.durationFeedback,
              decoration: BoxDecoration(
                color: (widget.isSelected || inBatch)
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : (_isHovered
                          ? theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3)
                          : Colors.transparent),
                border: Border(
                  left: BorderSide(
                    color: widget.isSelected || inBatch
                        ? theme.colorScheme.primary
                        : (_focusNode.hasFocus
                              ? theme.colorScheme.primary.withValues(alpha: 0.5)
                              : Colors.transparent),
                    width: 3.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space12,
              ),
              child: widget.isStacked
                  ? _buildStackedRow(context, fileMeta, catMeta)
                  : _buildWideRow(context, fileMeta, catMeta),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon(
    ({IconData icon, Color color, Color containerColor, String label}) fileMeta,
  ) {
    final inBatch = ref.watch(
      documentSelectionProvider.select((s) => s.contains(widget.doc.id)),
    );
    final selectionActive = ref.watch(
      documentSelectionProvider.select((s) => s.isNotEmpty),
    );
    final icon = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: fileMeta.containerColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        border: Border.all(color: fileMeta.color.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Icon(fileMeta.icon, color: fileMeta.color, size: 22),
      ),
    );
    if (!selectionActive) return icon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 28,
          child: Checkbox(
            value: inBatch,
            onChanged: (_) => ref
                .read(documentSelectionProvider.notifier)
                .toggle(widget.doc.id),
          ),
        ),
        icon,
      ],
    );
  }

  Widget _buildWideRow(
    BuildContext context,
    ({IconData icon, Color color, Color containerColor, String label}) fileMeta,
    ({IconData icon, Color color, Color containerColor, String label}) catMeta,
  ) {
    final theme = Theme.of(context);
    final doc = widget.doc;
    final docNum = doc.documentNumber?.trim();
    final formattedDocNum = (docNum != null && docNum.isNotEmpty)
        ? (docNum.startsWith('#') ? docNum : '#$docNum')
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildFileIcon(fileMeta),
        const SizedBox(width: AppTheme.space12),

        // Title and Document Number
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                doc.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: widget.isSelected
                      ? FontWeight.bold
                      : FontWeight.w600,
                  fontSize: 14,
                  color: widget.isSelected ? theme.colorScheme.primary : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (formattedDocNum != null) ...[
                const SizedBox(height: 2),
                Text(
                  formattedDocNum,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppTheme.space12),

        // Category with icon & container tint
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: catMeta.containerColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                border: Border.all(color: catMeta.color.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(catMeta.icon, size: 12, color: catMeta.color),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      doc.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: catMeta.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space12),

        // Date
        Expanded(
          flex: 2,
          child: Text(
            DocumentVisuals.formatDate(doc.documentDate),
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: AppTheme.space12),

        // Status Badge
        SyncStatusBadge(status: doc.syncStatus, onRetry: _handleRetrySync),
        const SizedBox(width: AppTheme.space8),

        // Overflow Actions Menu
        _buildPopupMenu(context),
      ],
    );
  }

  Widget _buildStackedRow(
    BuildContext context,
    ({IconData icon, Color color, Color containerColor, String label}) fileMeta,
    ({IconData icon, Color color, Color containerColor, String label}) catMeta,
  ) {
    final theme = Theme.of(context);
    final doc = widget.doc;
    final docNum = doc.documentNumber?.trim();
    final formattedDocNum = (docNum != null && docNum.isNotEmpty)
        ? (docNum.startsWith('#') ? docNum : '#$docNum')
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFileIcon(fileMeta),
        const SizedBox(width: AppTheme.space12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title and Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      doc.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: widget.isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 14,
                        color: widget.isSelected
                            ? theme.colorScheme.primary
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildPopupMenu(context),
                ],
              ),

              if (formattedDocNum != null) ...[
                const SizedBox(height: 2),
                Text(
                  formattedDocNum,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: AppTheme.space8),

              // Metadata Wrap: Category, Date, Status
              Wrap(
                spacing: AppTheme.space8,
                runSpacing: AppTheme.space4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: catMeta.containerColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                      border: Border.all(color: catMeta.color.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(catMeta.icon, size: 12, color: catMeta.color),
                        const SizedBox(width: 4),
                        Text(
                          doc.category,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: catMeta.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DocumentVisuals.formatDate(doc.documentDate),
                    style: theme.textTheme.labelSmall,
                  ),
                  SyncStatusBadge(
                    status: doc.syncStatus,
                    onRetry: _handleRetrySync,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    final doc = widget.doc;
    final hasDriveFile =
        doc.gdriveFileId != null &&
        doc.gdriveFileId!.isNotEmpty &&
        doc.syncStatus != DocumentSyncStatus.deleted;

    return PopupMenuButton<String>(
      key: _menuKey,
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      tooltip: 'Pilihan Dokumen',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (action) async {
        switch (action) {
          case 'open':
            FileOpenerService.openFile(doc.localFilePath, context);
            break;
          case 'open_folder':
            FileOpenerService.openFolder(doc.localFilePath, context);
            break;
          case 'check_status':
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
              final statusMeta = DocumentVisuals.getStatusMeta(
                context,
                newStatus,
              );
              CustomToast.show(
                context,
                title: 'Status Sinkronisasi',
                message: 'Status "${doc.title}": ${statusMeta.label}.',
                type: newStatus == DocumentSyncStatus.synced
                    ? ToastType.success
                    : ToastType.info,
              );
            }
            break;
          case 'rename_drive':
            DriveFileActionDialogs.showRenameDialog(
              context: context,
              ref: ref,
              doc: doc,
            );
            break;
          case 'delete_drive':
            DriveFileActionDialogs.showDeleteDialog(
              context: context,
              ref: ref,
              doc: doc,
            );
            break;
          case 'delete_local':
            _handleLocalDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'open',
          child: Row(
            children: [
              Icon(Icons.open_in_new_rounded, size: 16),
              SizedBox(width: AppTheme.space12),
              Text('Buka Dokumen'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'open_folder',
          child: Row(
            children: [
              Icon(Icons.folder_open_rounded, size: 16),
              SizedBox(width: AppTheme.space12),
              Text('Tampilkan di Folder'),
            ],
          ),
        ),
        if (hasDriveFile) ...[
          const PopupMenuDivider(height: 1),
          const PopupMenuItem(
            value: 'check_status',
            child: Row(
              children: [
                Icon(Icons.sync_rounded, size: 16),
                SizedBox(width: AppTheme.space12),
                Text('Periksa Status Drive'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'rename_drive',
            child: Row(
              children: [
                Icon(Icons.drive_file_rename_outline_rounded, size: 16),
                SizedBox(width: AppTheme.space12),
                Text('Ubah Nama di Drive'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete_drive',
            child: Row(
              children: [
                Icon(Icons.cloud_off_rounded, size: 16, color: Colors.red),
                SizedBox(width: AppTheme.space12),
                Text('Hapus dari Drive', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: 'delete_local',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
              SizedBox(width: AppTheme.space12),
              Text(
                'Pindahkan ke Tempat Sampah',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
