import 'dart:io';
import '../../features/documents/domain/repositories/document_repository.dart';

/// Service to seed realistic dummy documents across all system categories.
class DummyDataSeeder {
  static final List<({
    String title,
    String documentNumber,
    String category,
    DateTime documentDate,
    int fiscalYear,
    String extractedText,
    String fileName,
    String sampleContent,
  })> _dummyPresets = [
    (
      title: 'SK Tim Akselerasi Transformasi Digital 2026',
      documentNumber: '800/142/SK-TD/2026',
      category: 'SK',
      documentDate: DateTime(2026, 2, 15),
      fiscalYear: 2026,
      extractedText: 'Surat Keputusan penetapan tim akselerasi transformasi digital dan tata kelola arsip digital daerah.',
      fileName: 'SK_Tim_Transformasi_Digital_2026.pdf',
      sampleContent: 'Salinan Surat Keputusan Resmi Kepala Badan tentang Pembentukan Tim Akselerasi Transformasi Digital 2026.',
    ),
    (
      title: 'Laporan Akuntabilitas Kinerja Instansi Triwulan IV',
      documentNumber: 'LKJ/04/LAKIP/2026',
      category: 'Laporan',
      documentDate: DateTime(2026, 1, 20),
      fiscalYear: 2026,
      extractedText: 'Laporan evaluasi kinerja instansi triwulan IV dengan capaian target realisasi 94.8% dan serapan anggaran.',
      fileName: 'Laporan_Kinerja_Triwulan_IV_2026.xlsx',
      sampleContent: 'Ringkasan Laporan Akuntabilitas Kinerja Instansi Pemerintah (LKjIP) Triwulan IV Tahun 2026.',
    ),
    (
      title: 'Notula Rapat Koordinasi Penyusunan RKPD 2027',
      documentNumber: 'NOT/018/RKPD/2026',
      category: 'Notula',
      documentDate: DateTime(2026, 3, 10),
      fiscalYear: 2027,
      extractedText: 'Notulen rapat koordinasi lintas bidang terkait perencanaan anggaran RKPD dan prioritas pembangunan 2027.',
      fileName: 'Notula_Rapat_RKPD_2027.docx',
      sampleContent: 'Notulen Resmi Rapat Koordinasi Pembahasan Rencana Kerja Pemerintah Daerah (RKPD) Tahun 2027.',
    ),
    (
      title: 'Petunjuk Teknis Arsitektur SQLite FTS5 & Replikasi Sync',
      documentNumber: 'JUKNIS/02/TIK/2026',
      category: 'Teknis',
      documentDate: DateTime(2026, 2, 5),
      fiscalYear: 2026,
      extractedText: 'Spesifikasi teknis implementasi database SQLite FTS5 offline-first, background worker sync, dan SHA-256 integrity checksum.',
      fileName: 'Juknis_Arsitektur_SQLite_FTS5.pdf',
      sampleContent: 'Petunjuk Teknis Standar Arsitektur Database Lokal, SQLite Virtual Table FTS5, dan Sync Engine.',
    ),
    (
      title: 'Surat Keputusan Penetapan Alokasi Anggaran TIK 2027',
      documentNumber: 'KEP/009/TIK/2027',
      category: 'Surat Keputusan',
      documentDate: DateTime(2026, 10, 1),
      fiscalYear: 2027,
      extractedText: 'Ketetapan pimpinan mengenai alokasi anggaran infrastruktur server lokal, backup cloud storage, dan lisensi perangkat lunak.',
      fileName: 'SK_Alokasi_Anggaran_TIK_2027.pdf',
      sampleContent: 'Ketetapan Surat Keputusan Penetapan Alokasi Pembiayaan Sarana Prasarana TIK Tahun Anggaran 2027.',
    ),
    (
      title: 'Peraturan Standar Operasional Keamanan Data & Hashing',
      documentNumber: 'PERDA/04/SECR/2026',
      category: 'Peraturan',
      documentDate: DateTime(2026, 4, 18),
      fiscalYear: 2026,
      extractedText: 'Pedoman kepatuhan standar keamanan data informasi, verifikasi checksum berkas SHA-256, dan audit trail perizinan dokumen.',
      fileName: 'Peraturan_Keamanan_Data_2026.docx',
      sampleContent: 'Peraturan Tata Tertib Pedoman Kepatuhan Keamanan Informasi dan Verifikasi Checksum SHA-256.',
    ),
  ];

  /// Seeds dummy documents if the database currently has zero records.
  static Future<int> seedIfEmpty(DocumentRepository repository) async {
    final count = await repository.countDocuments();
    if (count > 0) return 0;
    return seedDocuments(repository);
  }

  /// Forces seeding of dummy documents across all categories.
  static Future<int> seedDocuments(DocumentRepository repository) async {
    final tempDir = Directory.systemTemp.createTempSync('dms_seed_');
    var createdCount = 0;

    try {
      for (final preset in _dummyPresets) {
        final tempFile = File('${tempDir.path}/${preset.fileName}');
        await tempFile.writeAsString(preset.sampleContent);

        await repository.importDocument(
          sourceFile: tempFile,
          title: preset.title,
          documentNumber: preset.documentNumber,
          category: preset.category,
          documentDate: preset.documentDate,
          fiscalYear: preset.fiscalYear,
          extractedText: preset.extractedText,
        );
        createdCount++;
      }
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }

    return createdCount;
  }
}
