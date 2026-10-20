import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:document_management/features/documents/presentation/widgets/add_document_modal.dart';

void main() {
  testWidgets(
    'AddDocumentModal renders modern form components and handles interaction',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: AddDocumentModal())),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Header
      expect(find.text('Tambah / Impor Dokumen'), findsOneWidget);
      expect(find.text('OFFLINE-FIRST'), findsOneWidget);

      // 2. Verify Hero Picker & Format Badges (Truthful wording without fake drag & drop)
      expect(
        find.text('Pilih Berkas Dokumen (Klik untuk Memilih)'),
        findsOneWidget,
      );
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('DOCX'), findsOneWidget);
      expect(find.text('XLSX'), findsOneWidget);

      // 3. Verify Form Fields
      expect(find.text('Judul Dokumen *'), findsOneWidget);
      expect(find.text('Nomor Dokumen (Opsional)'), findsOneWidget);

      // 4. Verify Category Chips
      expect(find.text('SK'), findsOneWidget);
      expect(find.text('Laporan'), findsOneWidget);
      expect(find.text('Notula'), findsOneWidget);
      expect(find.text('Teknis'), findsOneWidget);
      expect(find.text('Peraturan'), findsOneWidget);

      // Tap on 'Laporan' category chip to verify selection
      await tester.tap(find.text('Laporan'));
      await tester.pumpAndSettle();

      // 5. Verify Date and Fiscal Year
      expect(find.text('Tanggal Dokumen'), findsOneWidget);
      expect(find.textContaining('Tahun 2026'), findsOneWidget);

      // 6. Verify FTS5 Section
      expect(
        find.text('Kutipan & Teks Terindeks (FTS5 SQLite)'),
        findsOneWidget,
      );
      expect(find.text('FAST SEARCH'), findsOneWidget);

      // 7. Verify Action Buttons
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Simpan & Impor Dokumen'), findsOneWidget);

      // Tap Save without selecting a file -> triggers warning toast
      await tester.tap(find.text('Simpan & Impor Dokumen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Judul dokumen wajib diisi'), findsOneWidget);
    },
  );

  testWidgets(
    'AddDocumentModal prompts confirmation before closing dirty form',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog(
                  context: ctx,
                  builder: (_) =>
                      const ProviderScope(child: AddDocumentModal()),
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Type into title field to make form dirty
      await tester.enterText(
        find.byType(TextFormField).first,
        'Dokumen Penting 2026',
      );
      await tester.pumpAndSettle();

      // Tap Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Discard confirmation dialog appears
      expect(find.text('Buang Perubahan?'), findsOneWidget);
      expect(find.text('Batal'), findsWidgets);
      expect(find.text('Buang Perubahan'), findsOneWidget);

      // Confirm discard
      await tester.tap(find.text('Buang Perubahan'));
      await tester.pumpAndSettle();

      // Modal is closed
      expect(find.text('Tambah / Impor Dokumen'), findsNothing);
    },
  );
}
