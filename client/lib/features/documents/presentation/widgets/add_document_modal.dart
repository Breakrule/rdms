import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/hash_util.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../providers/document_providers.dart';

enum DuplicateChoice { cancel, keepSeparate }

class AddDocumentModal extends ConsumerStatefulWidget {
  const AddDocumentModal({super.key});

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
  bool _isHoveringDropzone = false;

  static List<int> get _fiscalYears {
    final current = DateTime.now().year;
    return List.generate(7, (i) => current + 1 - i);
  }

  static const Map<String, (IconData, Color, String)> _categories = {
    'SK': (
      Icons.verified_user_rounded,
      Color(0xFF2563EB),
      'Surat Keputusan Resmi',
    ),
    'Laporan': (
      Icons.analytics_rounded,
      Color(0xFF059669),
      'Laporan Berkala / Kinerja',
    ),
    'Notula': (
      Icons.history_edu_rounded,
      Color(0xFFD97706),
      'Notulen Rapat & Pembahasan',
    ),
    'Teknis': (
      Icons.terminal_rounded,
      Color(0xFF0891B2),
      'Spesifikasi & Dokumen Teknis',
    ),
    'Surat Keputusan': (
      Icons.military_tech_rounded,
      Color(0xFF7C3AED),
      'Ketetapan Tingkat Pimpinan',
    ),
    'Peraturan': (
      Icons.gavel_rounded,
      Color(0xFFDC2626),
      'Aturan & Regulasi Institusi',
    ),
  };

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

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  static (IconData, Color, String) _fileMeta(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => (Icons.picture_as_pdf_rounded, const Color(0xFFDC2626), 'PDF'),
      'doc' ||
      'docx' => (Icons.description_rounded, const Color(0xFF2563EB), 'DOCX'),
      'xls' ||
      'xlsx' ||
      'csv' => (Icons.table_chart_rounded, const Color(0xFF059669), 'XLSX'),
      'png' ||
      'jpg' ||
      'jpeg' => (Icons.image_rounded, const Color(0xFF9333EA), 'IMAGE'),
      _ => (Icons.insert_drive_file_rounded, const Color(0xFF0F52BA), 'FILE'),
    };
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
        final decision = await showDialog<DuplicateChoice>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Konten Identik Ditemukan'),
            content: Text(
              'Berkas ini identik dengan ${matches.length} dokumen tersimpan, '
              'mis. "${matches.first.title}". '
              'Buat catatan terpisah atau batalkan impornya?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, DuplicateChoice.cancel),
                child: const Text('Batal'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(ctx, DuplicateChoice.keepSeparate),
                child: const Text('Buat Catatan Terpisah'),
              ),
            ],
          ),
        );
        if (decision != DuplicateChoice.keepSeparate) {
          // Abandon this import; the form stays open so the user can
          // adjust metadata and retry deliberately.
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
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

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
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        elevation: 0,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 620,
              maxHeight: MediaQuery.of(context).size.height * 0.90,
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
                    // Header
                    _buildHeader(borderColor, textMuted),

                    // Form Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeroDropzone(
                                isDark,
                                cardBg,
                                borderColor,
                                textMuted,
                              ),
                              const SizedBox(height: 18),
                              _buildSectionHeader(
                                'INFORMASI UTAMA DOKUMEN',
                                'Identitas resmi dokumen untuk pencatatan sistem',
                                Icons.badge_outlined,
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _titleController,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: _inputDecoration(
                                  'Judul Dokumen *',
                                  'Misal: Surat Keputusan Pengangkatan Direksi 2026',
                                  Icons.edit_note_rounded,
                                  isDark,
                                  borderColor,
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Judul dokumen wajib diisi'
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _docNumberController,
                                style: const TextStyle(fontSize: 13.5),
                                decoration: _inputDecoration(
                                  'Nomor Dokumen (Opsional)',
                                  'Misal: 188.45/SK/2026 atau No. Dok/01/2026',
                                  Icons.tag_rounded,
                                  isDark,
                                  borderColor,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _buildSectionHeader(
                                'KLASIFIKASI KATEGORI',
                                'Pilih jenis arsip untuk filter dan navigasi cepat',
                                Icons.category_outlined,
                              ),
                              const SizedBox(height: 8),
                              _buildCategoryChips(isDark, borderColor),
                              const SizedBox(height: 18),
                              _buildSectionHeader(
                                'PERIODE & TANGGAL DOKUMEN',
                                'Waktu penerbitan dan tahun anggaran pembukuan',
                                Icons.event_note_rounded,
                              ),
                              const SizedBox(height: 8),
                              _buildPeriodSection(isDark, cardBg, borderColor),
                              const SizedBox(height: 18),
                              _buildFts5Section(
                                isDark,
                                cardBg,
                                borderColor,
                                textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Footer
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
                          color: const Color(0xFF059669).withValues(alpha: 0.3),
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

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF0F52BA)),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF0F52BA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    String label,
    String hint,
    IconData icon,
    bool isDark,
    Color borderColor,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        borderSide: const BorderSide(color: Color(0xFF0F52BA), width: 1.8),
      ),
    );
  }

  Widget _buildHeroDropzone(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textMuted,
  ) {
    if (_pickedFile != null) {
      final meta = _fileMeta(_pickedFile!.name);
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF059669)
              .withValues(alpha: isDark ? 0.12 : 0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusPanel),
          border: Border.all(
            color: const Color(0xFF059669).withValues(alpha: 0.4),
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: meta.$2.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(meta.$1, color: meta.$2, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pickedFile!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _formatBytes(
                            _pickedFile!.path != null
                                ? File(_pickedFile!.path!).lengthSync()
                                : 0,
                          ),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '•  Siap diimpor & dihitung SHA-256',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.swap_horiz_rounded, size: 15),
              label: const Text(
                'Ganti',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              onPressed: _pickFile,
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 18,
              ),
              onPressed: () => setState(() => _pickedFile = null),
            ),
          ],
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringDropzone = true),
      onExit: (_) => setState(() => _isHoveringDropzone = false),
      child: InkWell(
        onTap: _pickFile,
        borderRadius: BorderRadius.circular(AppTheme.radiusPanel),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          decoration: BoxDecoration(
            color: _isHoveringDropzone
                ? const Color(0xFF0F52BA)
                      .withValues(alpha: isDark ? 0.15 : 0.05)
                : cardBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusPanel),
            border: Border.all(
              color: _isHoveringDropzone
                  ? const Color(0xFF0F52BA)
                  : borderColor,
              width: _isHoveringDropzone ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.file_upload_outlined,
                color: Color(0xFF0F52BA),
                size: 36,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih Berkas Dokumen (Klik untuk Memilih)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                'Mendukung format PDF, Word (.docx), Excel (.xlsx), Gambar, dan Teks (.txt)',
                style: TextStyle(fontSize: 11.5, color: textMuted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: ['PDF', 'DOCX', 'XLSX', 'PNG/JPG', 'TXT']
                    .map(
                      (f) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          f,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark, Color borderColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.entries.map((entry) {
        final cat = entry.key;
        final meta = entry.value;
        final isSelected = _category == cat;

        return ChoiceChip(
          label: Text(cat),
          avatar: Icon(
            meta.$1,
            size: 16,
            color: isSelected ? Colors.white : meta.$2,
          ),
          selected: isSelected,
          selectedColor: meta.$2,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            side: BorderSide(color: isSelected ? meta.$2 : borderColor),
          ),
          onSelected: (selected) {
            if (selected) setState(() => _category = cat);
          },
        );
      }).toList(),
    );
  }

  Widget _buildPeriodSection(bool isDark, Color cardBg, Color borderColor) {
    final dateFormat = DateFormat('dd MMMM yyyy');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _documentDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2050),
                );
                if (picked != null) setState(() => _documentDate = picked);
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: Color(0xFF0F52BA),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal Dokumen',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        dateFormat.format(_documentDate),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(height: 32, width: 1, color: borderColor),
          const SizedBox(width: 12),
          DropdownButton<int>(
            value: _fiscalYear,
            underline: const SizedBox.shrink(),
            isDense: true,
            items: _fiscalYears.map((y) {
              return DropdownMenuItem(
                value: y,
                child: Text(
                  'Tahun $y',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _fiscalYear = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFts5Section(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.manage_search_rounded,
                size: 16,
                color: Color(0xFF0F52BA),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Kutipan & Teks Terindeks (FTS5 SQLite)',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F52BA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'FAST SEARCH',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F52BA),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _extractedTextController,
            maxLines: 3,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText:
                  'Ketik ringkasan, isi penting, atau kata kunci dokumen...',
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color borderColor, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showSecurityPill = constraints.maxWidth > 440;
          return Row(
            children: [
              if (showSecurityPill)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
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
                          Flexible(
                            child: Text(
                              'SHA-256 Otomatis',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final shouldClose = await _confirmDiscard();
                        if (shouldClose && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                child: Text('Batal', style: TextStyle(color: textMuted)),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
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
                  _isLoading ? 'Menyimpan...' : 'Simpan & Impor Dokumen',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
