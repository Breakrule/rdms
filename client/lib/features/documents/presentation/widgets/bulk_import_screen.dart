import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/bulk_import_service.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../presentation/providers/document_providers.dart';

/// Phase 4.4 bulk import. Select multiple files, apply shared
/// defaults, review per-file outcomes. Retrying a partially failed
/// batch does not duplicate completed items: already-imported content
/// is detected by hash and reported as "skipped duplicate".
class BulkImportScreen extends ConsumerStatefulWidget {
  const BulkImportScreen({super.key});

  @override
  ConsumerState<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends ConsumerState<BulkImportScreen> {
  final List<BulkImportItem> _items = [];
  String _category = 'SK';
  DateTime _date = DateTime.now();
  int _year = DateTime.now().year;
  bool _busy = false;
  List<BulkImportRow> _results = const [];

  Future<void> _pick() async {
    // file_picker 13: pickFiles returns the full selection as a list;
    // there is no allowMultiple flag anymore.
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Pilih berkas dokumen (maks. 100)',
    );
    if (files.isEmpty) return;
    final paths = files
        .map((f) => f.path)
        .whereType<String>()
        .toList(growable: false);
    if (paths.length > BulkImportService.maxBatchSize) {
      if (mounted) {
        CustomToast.show(
          context,
          title: 'Batch Terlalu Besar',
          message:
              'Maksimal ${BulkImportService.maxBatchSize} berkas per batch; '
              'diambil ${BulkImportService.maxBatchSize} pertama.',
          type: ToastType.warning,
        );
      }
      setState(() {
        _items
          ..clear()
          ..addAll(paths
              .take(BulkImportService.maxBatchSize)
              .map((p) => BulkImportItem(sourcePath: p)));
      });
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(paths.map((p) => BulkImportItem(sourcePath: p)));
      _results = const [];
    });
  }

  Future<void> _run() async {
    if (_items.isEmpty) return;
    setState(() {
      _busy = true;
      _results = const [];
    });
    try {
      final service = ref.read(bulkImportServiceProvider);
      final results = await service.importBatch(
        items: _items,
        defaultCategory: _category,
        defaultDate: _date,
        defaultFiscalYear: _year,
        onRowDone: (row) {
          if (mounted) setState(() => _results = [..._results, row]);
        },
      );
      setState(() => _results = results);
      ref.invalidate(allDocumentsStreamProvider);
      if (mounted) {
        final imported =
            results.where((r) => r.status == BulkImportRowStatus.imported).length;
        final skipped = results
            .where((r) => r.status == BulkImportRowStatus.skippedDuplicate)
            .length;
        final failed =
            results.where((r) => r.status == BulkImportRowStatus.failed).length;
        CustomToast.show(
          context,
          title: 'Impor Massal Selesai',
          message: '$imported diimpor, $skipped duplikat dilewati, $failed gagal.',
          type: failed == 0 ? ToastType.success : ToastType.warning,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final years = ref.watch(fiscalYearsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Impor Massal Dokumen')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(_items.isEmpty
                ? 'Pilih Berkas (file picker)'
                : '${_items.length} berkas dipilih — ubah'),
            onPressed: _busy ? null : _pick,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Kategori default'),
                  items: [
                    for (final c in ['SK', 'Laporan', 'Notula', 'Teknis', 'Peraturan'])
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: years.maybeWhen(
                  data: (list) => DropdownButtonFormField<int>(
                    initialValue: list.contains(_year) ? _year : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Tahun default'),
                    items: [for (final y in list) DropdownMenuItem(value: y, child: Text('$y'))],
                    onChanged: (v) {
                      if (v != null) setState(() => _year = v);
                    },
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Text('Tanggal default: ${_date.toIso8601String().substring(0, 10)}'),
            onPressed: _busy
                ? null
                : () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(1990),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(_busy ? 'Mengimpor…' : 'Mulai Impor (${_items.length})'),
            onPressed: (_items.isEmpty || _busy) ? null : _run,
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 16),
          for (final r in _results)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 3),
              child: ListTile(
                dense: true,
                leading: Icon(_iconFor(r.status),
                    color: _colorFor(theme, r.status)),
                title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: r.detail == null
                    ? null
                    : Text(r.detail!, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ),
          if (_results.isNotEmpty &&
              _results.any((r) => r.status == BulkImportRowStatus.imported))
            TextButton.icon(
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Selesai — tutup'),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(BulkImportRowStatus s) => switch (s) {
        BulkImportRowStatus.imported => Icons.check_circle_outline_rounded,
        BulkImportRowStatus.skippedDuplicate => Icons.content_copy_rounded,
        BulkImportRowStatus.failed => Icons.error_outline_rounded,
      };

  Color _colorFor(ThemeData theme, BulkImportRowStatus s) => switch (s) {
        BulkImportRowStatus.imported => Colors.green,
        BulkImportRowStatus.skippedDuplicate => Colors.orange,
        BulkImportRowStatus.failed => theme.colorScheme.error,
      };
}
