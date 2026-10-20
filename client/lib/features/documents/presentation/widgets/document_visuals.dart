import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/document_item.dart';

class DocumentVisuals {
  const DocumentVisuals._();

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _fullDateFormat = DateFormat('dd MMMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatFullDate(DateTime date) => _fullDateFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  static ({IconData icon, Color color, Color containerColor, String label})
  getFileIconMeta(String mimeType, [String? fileName]) {
    final lowerMime = mimeType.toLowerCase();
    final lowerExt = (fileName != null && fileName.contains('.'))
        ? fileName.split('.').last.toLowerCase()
        : '';

    if (lowerMime.contains('pdf') || lowerExt == 'pdf') {
      return (
        icon: Icons.picture_as_pdf_rounded,
        color: const Color(0xFFE11D48),
        containerColor: const Color(0xFFFFF1F2),
        label: 'PDF',
      );
    }
    if (lowerMime.contains('image') ||
        ['png', 'jpg', 'jpeg', 'webp'].contains(lowerExt)) {
      return (
        icon: Icons.image_rounded,
        color: const Color(0xFF8B5CF6),
        containerColor: const Color(0xFFF5F3FF),
        label: 'IMAGE',
      );
    }
    if (lowerMime.contains('sheet') ||
        lowerMime.contains('excel') ||
        lowerMime.contains('csv') ||
        ['xls', 'xlsx', 'csv'].contains(lowerExt)) {
      return (
        icon: Icons.table_chart_rounded,
        color: const Color(0xFF059669),
        containerColor: const Color(0xFFECFDF5),
        label: 'XLSX',
      );
    }
    if (lowerMime.contains('word') ||
        lowerMime.contains('officedocument') ||
        ['doc', 'docx'].contains(lowerExt)) {
      return (
        icon: Icons.description_rounded,
        color: const Color(0xFF2563EB),
        containerColor: const Color(0xFFEFF6FF),
        label: 'DOCX',
      );
    }
    if (lowerMime.contains('zip') ||
        lowerMime.contains('compressed') ||
        lowerMime.contains('tar') ||
        ['zip', 'rar', 'tar', 'gz'].contains(lowerExt)) {
      return (
        icon: Icons.folder_zip_rounded,
        color: const Color(0xFFD97706),
        containerColor: const Color(0xFFFFFBEB),
        label: 'ZIP',
      );
    }
    if (lowerMime.contains('text') || lowerExt == 'txt') {
      return (
        icon: Icons.article_rounded,
        color: const Color(0xFF0891B2),
        containerColor: const Color(0xFFECFEFF),
        label: 'TXT',
      );
    }

    return (
      icon: Icons.insert_drive_file_rounded,
      color: const Color(0xFF64748B),
      containerColor: const Color(0xFFF1F5F9),
      label: 'FILE',
    );
  }

  static ({IconData icon, Color color, Color containerColor, String label}) getCategoryMeta(String category) {
    switch (category) {
      case 'SK':
        return (
          icon: Icons.verified_rounded,
          color: const Color(0xFF2563EB),
          containerColor: const Color(0xFFEFF6FF),
          label: 'Surat Keputusan',
        );
      case 'Laporan':
        return (
          icon: Icons.assessment_rounded,
          color: const Color(0xFF059669),
          containerColor: const Color(0xFFECFDF5),
          label: 'Laporan',
        );
      case 'Notula':
        return (
          icon: Icons.history_edu_rounded,
          color: const Color(0xFFD97706),
          containerColor: const Color(0xFFFFFBEB),
          label: 'Notula Rapat',
        );
      case 'Teknis':
        return (
          icon: Icons.terminal_rounded,
          color: const Color(0xFF0891B2),
          containerColor: const Color(0xFFECFEFF),
          label: 'Dokumen Teknis',
        );
      case 'Surat Keputusan':
        return (
          icon: Icons.military_tech_rounded,
          color: const Color(0xFF7C3AED),
          containerColor: const Color(0xFFF5F3FF),
          label: 'Ketetapan Resmi',
        );
      case 'Peraturan':
        return (
          icon: Icons.gavel_rounded,
          color: const Color(0xFFE11D48),
          containerColor: const Color(0xFFFFF1F2),
          label: 'Peraturan',
        );
      case 'ALL':
      default:
        return (
          icon: Icons.dashboard_customize_rounded,
          color: const Color(0xFF2563EB),
          containerColor: const Color(0xFFEFF6FF),
          label: 'Semua Kategori',
        );
    }
  }

  static ({
    String label,
    IconData icon,
    Color foreground,
    Color background,
    String description,
  })
  getStatusMeta(BuildContext context, DocumentSyncStatus status) {
    final theme = Theme.of(context);
    final statusColors =
        theme.extension<RdmsStatusColors>() ??
        (theme.brightness == Brightness.dark
            ? RdmsStatusColors.dark
            : RdmsStatusColors.light);

    switch (status) {
      case DocumentSyncStatus.localOnly:
        return (
          label: 'Lokal Saja',
          icon: Icons.inventory_2_outlined,
          foreground: theme.colorScheme.onSurface.withValues(alpha: 0.75),
          background: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          description: 'Hanya tersimpan di perangkat lokal, belum diunggah ke Google Drive.',
        );
      case DocumentSyncStatus.queued:
        return (
          label: 'Dalam Antrean',
          icon: Icons.schedule_rounded,
          foreground: statusColors.info,
          background: statusColors.infoContainer,
          description:
              'Dokumen masuk antrean untuk sinkronisasi ke Google Drive.',
        );
      case DocumentSyncStatus.syncing:
        return (
          label: 'Mengunggah',
          icon: Icons.sync_rounded,
          foreground: statusColors.info,
          background: statusColors.infoContainer,
          description: 'Sedang mengunggah berkas ke Google Drive...',
        );
      case DocumentSyncStatus.synced:
        return (
          label: 'Tersimpan di Drive',
          icon: Icons.cloud_done_rounded,
          foreground: statusColors.success,
          background: statusColors.successContainer,
          description:
              'Dokumen terverifikasi tersimpan dan aman di Google Drive.',
        );
      case DocumentSyncStatus.error:
        return (
          label: 'Gagal Mengunggah',
          icon: Icons.error_outline_rounded,
          foreground: statusColors.error,
          background: statusColors.errorContainer,
          description:
              'Gagal mengunggah berkas ke Google Drive. Klik untuk coba lagi.',
        );
      case DocumentSyncStatus.deleted:
        return (
          label: 'Dihapus di Drive',
          icon: Icons.delete_outline_rounded,
          foreground: statusColors.warning,
          background: statusColors.warningContainer,
          description:
              'Berkas telah dihapus di Google Drive. Salinan lokal tetap aman.',
        );
      case DocumentSyncStatus.lost:
        return (
          label: 'Nama Berubah di Drive',
          icon: Icons.warning_amber_rounded,
          foreground: statusColors.warning,
          background: statusColors.warningContainer,
          description: 'Nama berkas di Google Drive tidak cocok dengan nama berkas lokal.',
        );
    }
  }
}
