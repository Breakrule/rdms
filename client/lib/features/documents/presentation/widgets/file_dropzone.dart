import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class FileDropzone extends StatefulWidget {
  final PlatformFile? pickedFile;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;
  final VoidCallback? onScanDocument;

  const FileDropzone({
    super.key,
    required this.pickedFile,
    required this.onPickFile,
    required this.onRemoveFile,
    this.onScanDocument,
  });

  @override
  State<FileDropzone> createState() => _FileDropzoneState();
}

class _FileDropzoneState extends State<FileDropzone> {
  bool _isHoveringDropzone = false;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final picked = widget.pickedFile;
    if (picked != null) {
      final meta = _fileMeta(picked.name);
      final fileSize = picked.path != null && File(picked.path!).existsSync()
          ? File(picked.path!).lengthSync()
          : 0;

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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: meta.$2.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(meta.$1, color: meta.$2, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    picked.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _formatBytes(fileSize),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          '• Siap diimpor',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Ganti berkas',
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.swap_horiz_rounded),
              onPressed: widget.onPickFile,
            ),
            IconButton(
              tooltip: 'Hapus berkas',
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
              ),
              onPressed: widget.onRemoveFile,
            ),
          ],
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringDropzone = true),
      onExit: (_) => setState(() => _isHoveringDropzone = false),
      child: InkWell(
        onTap: widget.onPickFile,
        borderRadius: BorderRadius.circular(AppTheme.radiusPanel),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          decoration: BoxDecoration(
            color: _isHoveringDropzone
                ? const Color(0xFF0F52BA).withValues(alpha: isDark ? 0.15 : 0.05)
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
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  for (final f in ['PDF', 'DOCX', 'XLSX', 'PNG/JPG', 'TXT'])
                    Container(
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
                  if (widget.onScanDocument != null)
                    ActionChip(
                      avatar: const Icon(Icons.camera_alt_rounded, size: 14),
                      label: const Text('Pindai Kamera'),
                      labelStyle: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onScanDocument,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
