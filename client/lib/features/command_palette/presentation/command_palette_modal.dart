import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/dummy_data_seeder.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../recovery/presentation/recovery_screen.dart';
import '../../documents/domain/models/document_item.dart';
import '../../documents/domain/search_query.dart';
import '../../documents/presentation/providers/document_providers.dart';
import '../../documents/presentation/widgets/document_visuals.dart';
import '../../documents/presentation/widgets/sync_status_badge.dart';

class CommandPaletteModal extends ConsumerStatefulWidget {
  final VoidCallback onOpenAddDocument;
  final VoidCallback onTriggerBulkSync;
  final void Function(DocumentItem doc)? onSelectDocument;

  const CommandPaletteModal({
    super.key,
    required this.onOpenAddDocument,
    required this.onTriggerBulkSync,
    this.onSelectDocument,
  });

  @override
  ConsumerState<CommandPaletteModal> createState() =>
      _CommandPaletteModalState();
}

class _CommandPaletteModalState extends ConsumerState<CommandPaletteModal> {
  final _searchController = TextEditingController();
  List<DocumentItem> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _performSearchDirect('');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String rawQuery) {
    _debounceTimer?.cancel();
    if (rawQuery.trim().isEmpty || rawQuery.trim().startsWith('>')) {
      _performSearchDirect(rawQuery);
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _performSearchDirect(rawQuery);
    });
  }

  Future<void> _performSearchDirect(String rawQuery) async {
    final query = rawQuery.trim();

    // Check if command mode (starts with '>')
    if (query.startsWith('>')) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final repo = ref.read(documentRepositoryProvider);
      // Phase 5.5: parse ALL prefix tokens together (combination, not
      // one-prefix-only) and run them through the SQLite paged query, so
      // facets compose and the FTS text stays parameterized/escaped.
      final dq = parseDocumentQuery(query);
      final results = await repo
          .watchDocumentPage(
            sortBy: 'newest',
            limit: 60,
            category: dq.category,
            fiscalYear: dq.fiscalYear,
            syncStatus: dq.syncStatus,
            documentNumber: dq.documentNumber,
            mimeType: dq.mimeType,
            fileNameLike: dq.fileName,
            tagName: dq.tag,
            dateFromMillis: dq.dateFromMillis,
            dateToMillis: dq.dateToMillis,
            search: dq.text.isEmpty ? null : dq.text,
          )
          .first;
      if (mounted) setState(() => _searchResults = results);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCommandMode = _searchController.text.trim().startsWith('>');

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusDialog),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
        child: Column(
          children: [
            // Search Input Header
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCommandMode
                        ? Icons.terminal_rounded
                        : Icons.search_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: isCommandMode
                            ? 'Ketik perintah sistem...'
                            : 'Cari dokumen atau ketik ">" untuk perintah...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: _performSearch,
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    ),
                  const SizedBox(width: AppTheme.space8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ESC',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Shortcuts Strip
            if (!isCommandMode)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.2,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text('Shortcut:', style: theme.textTheme.labelSmall),
                      const SizedBox(width: AppTheme.space8),
                      _buildChip('tahun:2026'),
                      const SizedBox(width: 6),
                      _buildChip('kategori:SK'),
                      const SizedBox(width: 6),
                      _buildChip('nama:surat'),
                      const SizedBox(width: 6),
                      _buildChip('> (Perintah)'),
                    ],
                  ),
                ),
              ),

            // Content Area
            Expanded(
              child: isCommandMode
                  ? _buildActionsList(context)
                  : _buildResultsList(context, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return InkWell(
      onTap: () {
        _searchController.text = label.startsWith('>') ? '> ' : '$label ';
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
        _performSearch(_searchController.text);
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActionsList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          leading: const Icon(Icons.add_circle_outline, color: Colors.green),
          title: const Text('Tambah / Impor Dokumen Baru'),
          subtitle: const Text(
            'Pilih berkas dari hard drive dan rekam metadata',
          ),
          onTap: () {
            Navigator.pop(context);
            widget.onOpenAddDocument();
          },
        ),
        ListTile(
          leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
          title: const Text('Upload Semua Berkas (Bulk Sync)'),
          subtitle: const Text(
            'Sinkronisasikan seluruh berkas antrean ke Google Drive',
          ),
          onTap: () {
            Navigator.pop(context);
            widget.onTriggerBulkSync();
          },
        ),
        ListTile(
          leading: const Icon(Icons.folder_open, color: Colors.amber),
          title: const Text('Ganti Direktori Penyimpanan Lokal'),
          subtitle: const Text('Pilih partisi atau folder penyimpanan baru'),
          onTap: () async {
            Navigator.pop(context);
            final dir = await FilePicker.getDirectoryPath();
            if (dir != null && dir.isNotEmpty) {
              await ref.read(storagePathProvider.notifier).updatePath(dir);
            }
          },
        ),
        ListTile(
          leading: const Icon(
            Icons.inventory_2_outlined,
            color: Color(0xFF0F52BA),
          ),
          title: const Text('Buka Pulihkan & Backup'),
          subtitle: const Text(
            'Tempat sampah lokal, ekspor/restore library, health check',
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RecoveryScreen(),
              ),
            );
          },
        ),
        if (kDebugMode)
          ListTile(
            leading: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF0F52BA),
            ),
            title: const Text('Muat Dokumen Contoh (Semua Kategori)'),
            subtitle: const Text(
              'Isi otomatis database dengan dokumen dummy untuk setiap kategori',
            ),
            onTap: () async {
              Navigator.pop(context);
              final repo = ref.read(documentRepositoryProvider);
              final count = await DummyDataSeeder.seedDocuments(repo);
              if (context.mounted) {
                CustomToast.show(
                  context,
                  title: 'Data Contoh Dimuat',
                  message:
                      '$count dokumen contoh berhasil ditambahkan ke database',
                  type: ToastType.success,
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildResultsList(BuildContext context, ThemeData theme) {
    if (_searchResults.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: Colors.grey.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tidak ada dokumen yang sesuai dengan pencarian',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.05)),
      itemBuilder: (context, index) {
        final doc = _searchResults[index];
        final fileMeta = DocumentVisuals.getFileIconMeta(
          doc.mimeType,
          doc.fileName,
        );

        return ListTile(
          dense: true,
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: fileMeta.containerColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(fileMeta.icon, color: fileMeta.color, size: 18),
          ),
          title: Text(
            doc.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${doc.category} • ${doc.fileName} • Tahun ${doc.fiscalYear}',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: SyncStatusBadge(status: doc.syncStatus),
          onTap: () {
            // Choosing result resets homepage query/category/year/status and activates document
            ref.read(documentFilterProvider.notifier).reset();
            Navigator.pop(context);
            if (widget.onSelectDocument != null) {
              widget.onSelectDocument!(doc);
            } else {
              ref.read(selectedDocumentProvider.notifier).select(doc);
            }
          },
        );
      },
    );
  }
}
