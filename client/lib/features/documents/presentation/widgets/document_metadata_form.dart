import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';

class DocumentMetadataForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController docNumberController;
  final TextEditingController extractedTextController;
  final DateTime documentDate;
  final int fiscalYear;
  final List<int> fiscalYears;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int> onFiscalYearChanged;

  const DocumentMetadataForm({
    super.key,
    required this.titleController,
    required this.docNumberController,
    required this.extractedTextController,
    required this.documentDate,
    required this.fiscalYear,
    required this.fiscalYears,
    required this.onDateChanged,
    required this.onFiscalYearChanged,
  });

  static Widget buildSectionHeader(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF0F52BA)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF0F52BA),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  static InputDecoration inputDecoration(
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
    final dateFormat = DateFormat('dd MMMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildSectionHeader(
          'INFORMASI UTAMA DOKUMEN',
          'Identitas resmi dokumen untuk pencatatan sistem',
          Icons.badge_outlined,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: titleController,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
          decoration: inputDecoration(
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
          controller: docNumberController,
          style: const TextStyle(fontSize: 13.5),
          decoration: inputDecoration(
            'Nomor Dokumen (Opsional)',
            'Misal: 188.45/SK/2026 atau No. Dok/01/2026',
            Icons.tag_rounded,
            isDark,
            borderColor,
          ),
        ),
        const SizedBox(height: 18),
        buildSectionHeader(
          'PERIODE & TANGGAL DOKUMEN',
          'Waktu penerbitan dan tahun anggaran pembukuan',
          Icons.event_note_rounded,
        ),
        const SizedBox(height: 8),
        Container(
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
                      initialDate: documentDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2050),
                    );
                    if (picked != null) onDateChanged(picked);
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: Color(0xFF0F52BA),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tanggal Dokumen',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              dateFormat.format(documentDate),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(height: 32, width: 1, color: borderColor),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: fiscalYear,
                underline: const SizedBox.shrink(),
                isDense: true,
                items: fiscalYears.map((y) {
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
                  if (val != null) onFiscalYearChanged(val);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
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
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
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
                controller: extractedTextController,
                maxLines: 3,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText:
                      'Ketik ringkasan, isi penting, atau kata kunci dokumen...',
                  hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.7)),
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
        ),
      ],
    );
  }
}
