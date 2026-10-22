import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/custom_toast.dart';
import '../../domain/models/document_item.dart';
import '../providers/document_providers.dart';
import '../../../metrics/data/metrics_emitters.dart';
import '../../../metrics/domain/metric_event.dart';

/// Phase 4.1 metadata editor. Mirrors the import form's validation but
/// every nullable field has an explicit "Hapus nilai" affordance so
/// "clear" is never ambiguous with "leave unchanged" (acceptance gate:
/// "clearing optional fields works"). Saving advances baseRevision and
/// queues a metadata-only backend job; no Drive upload is ever created
/// from this path (acceptance gate: "metadata-only edits do not upload
/// binaries").
class EditDocumentModal extends ConsumerStatefulWidget {
  final DocumentItem document;

  const EditDocumentModal({super.key, required this.document});

  static Future<void> show(BuildContext context, DocumentItem doc) {
    return showDialog(
      context: context,
      builder: (_) => EditDocumentModal(document: doc),
    );
  }

  @override
  ConsumerState<EditDocumentModal> createState() => _EditDocumentModalState();
}

class _EditDocumentModalState extends ConsumerState<EditDocumentModal> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.document.title);
  late final _docNumberController =
      TextEditingController(text: widget.document.documentNumber ?? '');
  late final _notesController =
      TextEditingController(text: widget.document.notes ?? '');
  late final _extractedController =
      TextEditingController(text: widget.document.extractedText ?? '');

  late DateTime _documentDate = widget.document.documentDate;
  late int _fiscalYear = widget.document.fiscalYear;
  late String _category = widget.document.category;

  bool _clearDocNumber = false;
  bool _clearExtracted = false;
  bool _isSaving = false;

  bool get _isDirty =>
      _titleController.text.trim() != widget.document.title ||
      (!_clearDocNumber &&
          _docNumberController.text.trim() !=
              (widget.document.documentNumber ?? '')) ||
      _clearDocNumber && widget.document.documentNumber != null ||
      _category != widget.document.category ||
      !_documentDate.isAtSameMomentAs(widget.document.documentDate) ||
      _fiscalYear != widget.document.fiscalYear ||
      _notesController.text.trim() != (widget.document.notes ?? '') ||
      (!_clearExtracted &&
          _extractedController.text.trim() !=
              (widget.document.extractedText ?? ''));

  @override
  void dispose() {
    _titleController.dispose();
    _docNumberController.dispose();
    _notesController.dispose();
    _extractedController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buang Perubahan?'),
        content: const Text(
          'Perubahan pada formulir belum disimpan. Tutup tanpa menyimpan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(documentRepositoryProvider);
      final updated = await repo.updateDocumentMetadata(
        id: widget.document.id,
        title: _titleController.text.trim(),
        documentNumber: _clearDocNumber ? null : _docNumberController.text.trim(),
        clearDocumentNumber: _clearDocNumber,
        category: _category,
        documentDate: _documentDate,
        fiscalYear: _fiscalYear,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        clearNotes: _notesController.text.trim().isEmpty && widget.document.notes != null,
        extractedText:
            _clearExtracted ? null : _extractedController.text.trim(),
        clearExtractedText: _clearExtracted,
      );
      // Rev.2 P0.3: PRD metric 3's `misfiled` signal is "category corrected
      // within 7 days of import", so only a REAL diff is recorded — an
      // unchanged save must not inflate the rate. Values are compared from the
      // row the repository just returned; no field text is stored.
      final changedFields = <EditedField>[
        if (updated.title != widget.document.title) EditedField.title,
        if (updated.documentNumber != widget.document.documentNumber)
          EditedField.documentNumber,
        if (updated.category != widget.document.category) EditedField.category,
        if (updated.documentDate != widget.document.documentDate)
          EditedField.documentDate,
        if (updated.fiscalYear != widget.document.fiscalYear)
          EditedField.fiscalYear,
        if (updated.notes != widget.document.notes) EditedField.notes,
      ];
      emitMetadataEdited(
        ref,
        document: widget.document,
        fields: changedFields,
      );

      // Queue only the backend metadata job (never a Drive upload).
      final binding = await ref.read(syncAccountBindingProvider.future);
      await ref
          .read(syncQueueServiceProvider)
          .enqueueMetadataOnly(doc: updated, accountBinding: binding);
      if (mounted) {
        Navigator.of(context).pop();
        CustomToast.show(
          context,
          title: 'Perubahan Disimpan',
          message:
              '"${updated.title}" diperbarui (revisi ${updated.baseRevision}) dan antrean metadata disiapkan.',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          title: 'Gagal Menyimpan',
          message: '$e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final yearsAsync = ref.watch(fiscalYearsProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final dateFormat = DateFormat('yyyy-MM-dd');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: AlertDialog(
        title: const Text('Edit Metadata Dokumen'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Judul wajib diisi'
                        : (v.trim().length > 255 ? 'Maks. 255 karakter' : null),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _docNumberController,
                    enabled: !_clearDocNumber,
                    decoration: InputDecoration(
                      labelText: 'Nomor Dokumen',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _clearDocNumber ? 'Batal hapus' : 'Hapus nilai',
                        icon: Icon(_clearDocNumber
                            ? Icons.undo_rounded
                            : Icons.clear_rounded),
                        onPressed: () => setState(() {
                          _clearDocNumber = !_clearDocNumber;
                        }),
                      ),
                    ),
                    validator: (v) => !_clearDocNumber && (v?.length ?? 0) > 100
                        ? 'Maks. 100 karakter'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  categoriesAsync.maybeWhen(
                    data: (cats) => DropdownButtonFormField<String>(
                      initialValue: _category,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      items: {
                        // Keep the doc's current code even if it is not
                        // in the table yet (legacy value).
                        _category,
                        for (final c in cats) c.code,
                      }
                          .map((code) => DropdownMenuItem(
                                value: code,
                                child: Text(
                                  cats
                                      .where((c) => c.code == code)
                                      .map((c) => c.name)
                                      .firstOrNull ??
                                      code,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _category = v);
                      },
                    ),
                    orElse: () => const LinearProgressIndicator(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event_outlined, size: 18),
                          label: Text(dateFormat.format(_documentDate)),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _documentDate,
                              firstDate: DateTime(1990),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _documentDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: yearsAsync.maybeWhen(
                          data: (years) => DropdownButtonFormField<int>(
                            initialValue: years.contains(_fiscalYear)
                                ? _fiscalYear
                                : null,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Tahun Anggaran',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              for (final y in years)
                                DropdownMenuItem(value: y, child: Text('$y')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _fiscalYear = v);
                            },
                          ),
                          orElse: () => const SizedBox(height: 56),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                      border: OutlineInputBorder(),
                      hintText: 'Kosongkan untuk menghapus catatan',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _extractedController,
                    enabled: !_clearExtracted,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Isi Teks Dokumen (Pencarian)',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _clearExtracted ? 'Batal hapus' : 'Hapus nilai',
                        icon: Icon(_clearExtracted
                            ? Icons.undo_rounded
                            : Icons.clear_rounded),
                        onPressed: () => setState(() {
                          _clearExtracted = !_clearExtracted;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Perubahan metadata dokumen disimpan secara aman di database lokal.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final shouldDiscard = await _confirmDiscard();
              if (shouldDiscard && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_rounded, size: 18),
            label: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
