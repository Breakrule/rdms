import 'package:flutter/material.dart';

/// Single category definition with visual attributes.
class DocumentCategoryDefinition {
  final String key;
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  const DocumentCategoryDefinition({
    required this.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

/// Central single source of truth for document categories and their presentation metadata.
class DocumentCategories {
  DocumentCategories._();

  static const List<String> defaultKeys = [
    'ALL',
    'SK',
    'Laporan',
    'Notula',
    'Teknis',
    'Peraturan',
  ];

  static const Map<String, DocumentCategoryDefinition> definitions = {
    'SK': DocumentCategoryDefinition(
      key: 'SK',
      name: 'Surat Keputusan',
      icon: Icons.verified_user_rounded,
      color: Color(0xFF2563EB),
      description: 'Surat Keputusan Resmi',
    ),
    'Laporan': DocumentCategoryDefinition(
      key: 'Laporan',
      name: 'Laporan',
      icon: Icons.analytics_rounded,
      color: Color(0xFF059669),
      description: 'Laporan Berkala / Kinerja',
    ),
    'Notula': DocumentCategoryDefinition(
      key: 'Notula',
      name: 'Notula',
      icon: Icons.history_edu_rounded,
      color: Color(0xFFD97706),
      description: 'Notulen Rapat & Pembahasan',
    ),
    'Teknis': DocumentCategoryDefinition(
      key: 'Teknis',
      name: 'Teknis',
      icon: Icons.terminal_rounded,
      color: Color(0xFF0891B2),
      description: 'Spesifikasi & Dokumen Teknis',
    ),
    'Surat Keputusan': DocumentCategoryDefinition(
      key: 'Surat Keputusan',
      name: 'Surat Keputusan',
      icon: Icons.military_tech_rounded,
      color: Color(0xFF7C3AED),
      description: 'Ketetapan Tingkat Pimpinan',
    ),
    'Peraturan': DocumentCategoryDefinition(
      key: 'Peraturan',
      name: 'Peraturan',
      icon: Icons.gavel_rounded,
      color: Color(0xFFDC2626),
      description: 'Aturan & Regulasi Institusi',
    ),
  };

  /// Returns the definition for [key], or a fallback for unknown/custom categories.
  static DocumentCategoryDefinition get(String key) {
    return definitions[key] ??
        DocumentCategoryDefinition(
          key: key,
          name: key,
          icon: Icons.description_rounded,
          color: const Color(0xFF6B7280),
          description: key,
        );
  }
}
