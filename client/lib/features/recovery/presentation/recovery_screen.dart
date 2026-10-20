import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/library_backup_service.dart';
import '../../../core/services/library_integrity_service.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../documents/domain/models/document_item.dart';
import '../../documents/presentation/providers/document_providers.dart';
import '../../documents/presentation/widgets/document_visuals.dart';

/// Phase 1 recovery hub. One screen, three tabs:
/// - Trash: recycle-bin view with restore/purge actions.
/// - Backup: export the library to a folder, restore from a folder.
/// - Health: run an integrity check and inspect findings.
///
/// Reachable from the sidebar and via the command palette
/// (`> Buka Pulihkan & Backup`).
class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key});

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulihkan & Backup'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Tempat Sampah'),
            Tab(text: 'Backup'),
            Tab(text: 'Kesehatan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _TrashTab(),
          _BackupTab(),
          _HealthTab(),
        ],
      ),
    );
  }
}

class _TrashTab extends ConsumerWidget {
  const _TrashTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashedAsync = ref.watch(trashedDocumentsStreamProvider);
    return trashedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Gagal memuat tempat sampah: $e')),
      data: (docs) {
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline_rounded, size: 48),
                SizedBox(height: 12),
                Text('Tempat sampah lokal kosong.'),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final catMeta = DocumentVisuals.getCategoryMeta(doc.category);
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: catMeta.containerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(catMeta.icon, color: catMeta.color, size: 20),
              ),
              title: Text(
                doc.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${catMeta.label} • Dibuang ${doc.trashedAt == null ? '?' : DateFormat('y-MM-dd HH:mm').format(doc.trashedAt!)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.restore_rounded, size: 16),
                    onPressed: () => _restore(context, ref, doc),
                    label: const Text('Pulihkan'),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_forever_rounded, size: 16),
                    onPressed: () => _purge(context, ref, doc),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    label: const Text('Hapus Permanen'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    DocumentItem doc,
  ) async {
    try {
      await ref.read(documentRepositoryProvider).restoreDocument(doc.id);
      ref.invalidate(documentsListStreamProvider);
      ref.invalidate(documentSummaryStreamProvider);
      ref.invalidate(filteredDocumentCountProvider);
      ref.invalidate(allDocumentsStreamProvider);
      ref.invalidate(trashedDocumentsStreamProvider);
      if (context.mounted) {
        CustomToast.show(
          context,
          title: 'Dipulihkan',
          message: 'Dokumen "${doc.title}" dikembalikan ke library aktif.',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.show(
          context,
          title: 'Gagal Memulihkan',
          message: '$e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _purge(
    BuildContext context,
    WidgetRef ref,
    DocumentItem doc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Permanen?'),
        content: Text(
          'Berkas "${doc.title}" dan metadata-nya akan hilang dari perangkat ini. '
          'Salinan di Google Drive (jika ada) tidak terpengaruh. Tindakan ini '
          'tidak bisa dibatalkan.',
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
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(documentRepositoryProvider).deleteDocument(doc.id);
      ref.invalidate(documentsListStreamProvider);
      ref.invalidate(documentSummaryStreamProvider);
      ref.invalidate(filteredDocumentCountProvider);
      ref.invalidate(allDocumentsStreamProvider);
      ref.invalidate(trashedDocumentsStreamProvider);
      if (context.mounted) {
        CustomToast.show(
          context,
          title: 'Dihapus Permanen',
          message: 'Berkas dan metadata "${doc.title}" dihapus dari lokal.',
          type: ToastType.info,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.show(
          context,
          title: 'Gagal Menghapus',
          message: '$e',
          type: ToastType.error,
        );
      }
    }
  }
}

class _BackupTab extends ConsumerStatefulWidget {
  const _BackupTab();

  @override
  ConsumerState<_BackupTab> createState() => _BackupTabState();
}

class _BackupTabState extends ConsumerState<_BackupTab> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Backup portable',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Ekspor menyimpan metadata dan berkas yang dikelola ke sebuah folder. '
          'Restore membaca folder tersebut, memverifikasi SHA-256 tiap berkas, '
          'dan menolak path yang mencoba keluar dari folder backup.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _export,
          icon: const Icon(Icons.save_alt_rounded),
          label: const Text('Ekspor Library ke Folder'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _restoreFromBackup,
          icon: const Icon(Icons.folder_open_rounded),
          label: const Text('Restore dari Folder Backup'),
        ),
        if (_busy) ...[
          const SizedBox(height: 20),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Future<void> _export() async {
    final dir = await FilePicker.getDirectoryPath(
      dialogTitle: 'Pilih folder tujuan backup',
    );
    if (dir == null) return;
    setState(() => _busy = true);
    try {
      final service = ref.read(libraryBackupServiceProvider);
      final summary = await service.exportLibrary(Directory(dir));
      if (mounted) {
        CustomToast.show(
          context,
          title: 'Backup Selesai',
          message:
              '${summary.documentCount} dokumen diekspor; ${summary.filesMissing} berkas hilang saat ekspor.',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          title: 'Ekspor Gagal',
          message: '$e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreFromBackup() async {
    final dir = await FilePicker.getDirectoryPath(
      dialogTitle: 'Pilih folder backup',
    );
    if (dir == null) return;
    final policy = await _askConflictPolicy();
    if (policy == null) return;

    final rootPath = await ref.read(storagePathProvider.future);
    setState(() => _busy = true);
    try {
      final service = ref.read(libraryBackupServiceProvider);
      final summary = await service.restoreBackup(
        Directory(dir),
        rootDir: Directory(rootPath),
        policy: policy,
      );
      if (mounted) {
        CustomToast.show(
          context,
          title: 'Restore Selesai',
          message:
              '${summary.restored} dipulihkan, ${summary.overwritten} ditimpa, ${summary.skipped} dilewati.',
          type: ToastType.success,
        );
        ref.invalidate(documentsListStreamProvider);
        ref.invalidate(allDocumentsStreamProvider);
        ref.invalidate(trashedDocumentsStreamProvider);
        ref.invalidate(documentSummaryStreamProvider);
        ref.invalidate(filteredDocumentCountProvider);
      }
    } on BackupInvalidException catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          title: 'Backup Ditolak',
          message: e.message,
          type: ToastType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          title: 'Restore Gagal',
          message: '$e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<ConflictPolicy?> _askConflictPolicy() async {
    return showDialog<ConflictPolicy>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Policy Konflik ID'),
        content: const Text(
          'Beberapa dokumen di backup bisa jadi sudah ada di library. '
          'Pilih bagaimana restore harus bersikap terhadap konflik ID:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ConflictPolicy.abort),
            child: const Text('Batalkan kalau ada konflik'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ConflictPolicy.skip),
            child: const Text('Lewati konflik'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ConflictPolicy.overwrite),
            child: const Text('Timpa dengan backup'),
          ),
        ],
      ),
    );
  }
}

class _HealthTab extends ConsumerStatefulWidget {
  const _HealthTab();

  @override
  ConsumerState<_HealthTab> createState() => _HealthTabState();
}

class _HealthTabState extends ConsumerState<_HealthTab> {
  IntegrityReport? _report;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton.icon(
            onPressed: _busy ? null : _run,
            icon: const Icon(Icons.monitor_heart_outlined),
            label: const Text('Jalankan Health Check'),
          ),
        ),
        if (_busy) const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
        if (report != null)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Text(
                  'Dokumen diperiksa: ${report.documentsScanned}. '
                  'Temuan: ${report.findings.length}.',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                if (report.isClean)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: Colors.teal.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.teal,
                          size: 22,
                        ),
                      ),
                      title: const Text(
                        'Library Bersih',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Semua berkas fisik dan rekaman metadata cocok tanpa anomali.',
                      ),
                    ),
                  ),
                for (final finding in report.findings)
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.15),
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _colorFor(context, finding.kind)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _iconFor(finding.kind),
                          color: _colorFor(context, finding.kind),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        _labelFor(finding.kind),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${finding.detail}${finding.path == null ? '' : '\n${finding.path}'}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      final root = await ref.read(storagePathProvider.future);
      final service = ref.read(libraryIntegrityServiceProvider);
      final report = await service.check(storageRootPath: root);
      if (mounted) setState(() => _report = report);
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          title: 'Health Check Gagal',
          message: '$e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _labelFor(IntegrityFindingKind kind) {
    switch (kind) {
      case IntegrityFindingKind.missingFile:
        return 'Berkas Fisik Hilang';
      case IntegrityFindingKind.contentChanged:
        return 'Isi Berkas Berubah';
      case IntegrityFindingKind.unreadableFile:
        return 'Berkas Tidak Dapat Dibaca';
      case IntegrityFindingKind.orphanFile:
        return 'Berkas Tidak Terdaftar';
      case IntegrityFindingKind.storageRootUnavailable:
        return 'Folder Penyimpanan Tidak Ditemukan';
      case IntegrityFindingKind.interruptedOperation:
        return 'Operasi Terinterupsi';
    }
  }

  Color _colorFor(BuildContext context, IntegrityFindingKind kind) {
    final theme = Theme.of(context);
    switch (kind) {
      case IntegrityFindingKind.missingFile:
      case IntegrityFindingKind.storageRootUnavailable:
        return theme.colorScheme.error;
      case IntegrityFindingKind.contentChanged:
      case IntegrityFindingKind.unreadableFile:
      case IntegrityFindingKind.interruptedOperation:
        return Colors.orange.shade700;
      case IntegrityFindingKind.orphanFile:
        return Colors.blue.shade600;
    }
  }

  IconData _iconFor(IntegrityFindingKind kind) {
    switch (kind) {
      case IntegrityFindingKind.missingFile:
        return Icons.warning_amber_rounded;
      case IntegrityFindingKind.contentChanged:
        return Icons.difference_outlined;
      case IntegrityFindingKind.unreadableFile:
        return Icons.lock_outline;
      case IntegrityFindingKind.orphanFile:
        return Icons.copy_all_rounded;
      case IntegrityFindingKind.storageRootUnavailable:
        return Icons.folder_off_outlined;
      case IntegrityFindingKind.interruptedOperation:
        return Icons.pause_circle_outline_rounded;
    }
  }
}
