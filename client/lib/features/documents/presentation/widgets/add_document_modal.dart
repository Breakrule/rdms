import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/hash_util.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../camera_ocr/presentation/camera_capture_screen.dart';
import '../../../camera_ocr/presentation/ocr_review_screen.dart';
import '../providers/document_providers.dart';
import '../../../metrics/data/metrics_emitters.dart';
import 'category_selector.dart';
import 'document_metadata_form.dart';
import 'duplicate_check_dialog.dart';
import 'file_dropzone.dart';

class AddDocumentModal extends ConsumerStatefulWidget {
  final PlatformFile? initialPickedFile;

  const AddDocumentModal({super.key, this.initialPickedFile});

  @override
  ConsumerState<AddDocumentModal> createState() => _AddDocumentModalState();
}

class _AddDocumentModalState extends ConsumerState<AddDocumentModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _docNumberController = TextEditingController();
  final _extractedTextController = TextEditingController();

  DateTime _documentDate = DateTime.now();
  int _fiscalYear = DateTime.now().year;
  String _category = 'SK';
  PlatformFile? _pickedFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPickedFile != null) {
      _pickedFile = widget.initialPickedFile;
      _titleController.text = _pickedFile!.name.split('.').first;
    }
  }

  static List<int> get _fiscalYears {
    final current = DateTime.now().year;
    return List.generate(7, (i) => current + 1 - i);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _docNumberController.dispose();
    _extractedTextController.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _pickedFile != null ||
      _titleController.text.trim().isNotEmpty ||
      _docNumberController.text.trim().isNotEmpty ||
      _extractedTextController.text.trim().isNotEmpty;

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buang Perubahan?'),
        content: const Text(
          'Data formulir yang belum disimpan akan hilang. Apakah Anda yakin ingin menutup?',
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
            child: const Text('Buang Perubahan'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles();
    if (result.isNotEmpty) {
      setState(() {
        _pickedFile = result.first;
        if (_titleController.text.trim().isEmpty) {
          final name = _pickedFile!.name;
          final dotIndex = name.lastIndexOf('.');
          _titleController.text = dotIndex > 0
              ? name.substring(0, dotIndex)
              : name;
        }
      });
    }
  }

  bool get _canScanCamera => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> _scanDocumentFromCamera() async {
    final result = await Navigator.of(context).push<OcrCaptureResult>(
      MaterialPageRoute(
        builder: (ctx) => const CameraCaptureScreen(),
      ),
    );

    if (result != null && mounted) {
      final file = result.file;
      final fileName = file.path.split(Platform.pathSeparator).last;

      setState(() {
        _pickedFile = _CapturedPlatformFile(file);

        if (result.extractedText.isNotEmpty) {
          _extractedTextController.text = result.extractedText;
        }

        if (_titleController.text.trim().isEmpty) {
          final lines = result.extractedText
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty && l.length > 3)
              .toList();
          if (lines.isNotEmpty) {
            final candidate = lines.first;
            _titleController.text = candidate.length > 50
                ? candidate.substring(0, 50).trim()
                : candidate;
          } else {
            final rawName = fileName.contains('.')
                ? fileName.substring(0, fileName.lastIndexOf('.'))
                : fileName;
            _titleController.text = 'Pindaian $rawName';
          }
        }
      });

      CustomToast.show(
        context,
        title: 'Dokumen Berhasil Dipindai',
        message: result.extractedText.isNotEmpty
            ? 'Teks dokumen berhasil diekstraksi (${result.extractedText.length} karakter).'
            : 'Foto dokumen tersimpan tanpa teks terdeteksi.',
        type: ToastType.success,
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null || _pickedFile!.path == null) {
      CustomToast.show(
        context,
        title: 'Berkas Diperlukan',
        message: 'Silakan pilih berkas dokumen fisik yang akan diimpor.',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(documentRepositoryProvider);

      // Phase 4.5 duplicate detection: hash the SOURCE before copying;
      // a hit requires an explicit user choice. Never auto-merge, never
      // auto-delete either record.
      final source = File(_pickedFile!.path!);
      final hash = await HashUtil.calculateFileSha256(source);
      final matches = await repo.findBySha256(hash);
      if (matches.isNotEmpty) {
        if (mounted) setState(() => _isLoading = false);
        if (!mounted) return;
        final decision = await showDuplicateCheckDialog(
          context: context,
          matchCount: matches.length,
          sampleTitle: matches.first.title,
        );
        // Rev.2 P0.3: the duplicate check is PRD metric 3's
        // `duplicate_filed` guard. Recording the decision (including
        // "cancelled", which is the check working) is how the 30 % error
        // reduction claim becomes a number rather than an aspiration.
        emitDuplicateDecision(ref, decision);
        if (decision != DuplicateChoice.keepSeparate) {
          return;
        }
        if (mounted) setState(() => _isLoading = true);
      }

      final doc = await repo.importDocument(
        sourceFile: source,
        title: _titleController.text.trim(),
        documentNumber: _docNumberController.text.trim().isNotEmpty
            ? _docNumberController.text.trim()
            : null,
        category: _category,
        documentDate: _documentDate,
        fiscalYear: _fiscalYear,
        extractedText: _extractedTextController.text.trim().isNotEmpty
            ? _extractedTextController.text.trim()
            : null,
      );

      ref.read(selectedDocumentProvider.notifier).select(doc);
      if (mounted) {
        Navigator.of(context).pop();
        CustomToast.show(
          context,
          title: 'Dokumen Berhasil Diimpor',
          message: '"${doc.title}" tersimpan dan siap digunakan.',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          title: 'Gagal Mengimpor Dokumen',
          message: '$e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final viewPadding = MediaQuery.viewPaddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final topPadding = math.max(16.0, viewPadding.top + 8.0);
    final bottomPadding =
        math.max(16.0, viewPadding.bottom + 12.0 + viewInsets.bottom);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldClose = await _confirmDiscard();
        if (shouldClose && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.fromLTRB(16, topPadding, 16, bottomPadding),
        elevation: 0,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 620,
              maxHeight: MediaQuery.sizeOf(context).height * 0.88,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusDialog),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.18),
                    blurRadius: 36,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusDialog),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(borderColor, textMuted),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FileDropzone(
                                pickedFile: _pickedFile,
                                onPickFile: _pickFile,
                                onRemoveFile: () =>
                                    setState(() => _pickedFile = null),
                                onScanDocument: _canScanCamera
                                    ? _scanDocumentFromCamera
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              DocumentMetadataForm.buildSectionHeader(
                                'KLASIFIKASI KATEGORI',
                                'Pilih jenis arsip untuk filter dan navigasi cepat',
                                Icons.category_outlined,
                              ),
                              const SizedBox(height: 8),
                              CategorySelector(
                                selectedCategory: _category,
                                onSelected: (cat) =>
                                    setState(() => _category = cat),
                              ),
                              const SizedBox(height: 18),
                              DocumentMetadataForm(
                                titleController: _titleController,
                                docNumberController: _docNumberController,
                                extractedTextController:
                                    _extractedTextController,
                                documentDate: _documentDate,
                                fiscalYear: _fiscalYear,
                                fiscalYears: _fiscalYears,
                                onDateChanged: (d) =>
                                    setState(() => _documentDate = d),
                                onFiscalYearChanged: (y) =>
                                    setState(() => _fiscalYear = y),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildFooter(borderColor, textMuted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color borderColor, Color textMuted) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusControl),
            ),
            child: const Icon(
              Icons.note_add_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    const Text(
                      'Tambah / Impor Dokumen',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color:
                              const Color(0xFF059669).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 11,
                            color: Color(0xFF059669),
                          ),
                          SizedBox(width: 2),
                          Text(
                            'OFFLINE-FIRST',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Impor berkas ke penyimpanan lokal dengan indeks pencarian instan',
                  style: TextStyle(fontSize: 11.5, color: textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            splashRadius: 18,
            onPressed: () async {
              final shouldClose = await _confirmDiscard();
              if (shouldClose && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color borderColor, Color textMuted) {
    return SafeArea(
      top: false,
      maintainBottomViewPadding: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showSecurityPill = constraints.maxWidth > 460;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showSecurityPill)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 13,
                          color: Color(0xFF059669),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'SHA-256 Otomatis',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                final shouldClose = await _confirmDiscard();
                                if (shouldClose && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                        child:
                            Text('Batal', style: TextStyle(color: textMuted)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_rounded, size: 16),
                          label: Text(
                            _isLoading
                                ? 'Menyimpan...'
                                : 'Simpan & Impor Dokumen',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

base class _CapturedPlatformFile extends PlatformFile {
  @override
  final String name;
  @override
  final Uri uri;
  final File _file;

  _CapturedPlatformFile(File file)
      : _file = file,
        name = file.path.split(Platform.pathSeparator).last,
        uri = file.uri;

  @override
  String? get path => _file.path;

  @override
  XFile get xFile => XFile(_file.path);

  @override
  int? lengthSync() => _file.existsSync() ? _file.lengthSync() : null;

  @override
  Future<int?> length() async =>
      _file.existsSync() ? await _file.length() : null;

  @override
  Future<Uint8List> readAsBytes() => _file.readAsBytes();

  @override
  Stream<Uint8List> readAsByteStream() =>
      _file.openRead().map((chunk) => Uint8List.fromList(chunk));
}
