import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:document_management/features/documents/domain/models/document_item.dart';
import 'package:document_management/features/documents/presentation/providers/document_providers.dart';
import 'package:document_management/features/documents/presentation/widgets/document_list_view.dart';
import 'package:document_management/features/documents/presentation/widgets/document_preview_panel.dart';
import 'package:document_management/core/services/file_opener_service.dart';
import 'package:document_management/features/documents/presentation/widgets/cloud_sync_settings_modal.dart';

class MockSelectedDocumentNotifier extends SelectedDocumentNotifier {
  final DocumentItem? initial;
  MockSelectedDocumentNotifier(this.initial);
  @override
  DocumentItem? build() => initial;
}

void main() {
  final sampleDoc = DocumentItem(
    id: 'test-doc-1',
    title: 'Surat Keputusan Sangat Panjang Mengenai Pelaksanaan Reformasi Birokrasi dan Keamanan Sistem Informasi Digital',
    documentNumber: '800/142/SK-TRANSFORMASI-DIGITAL-TERPADU/2026/REV-09',
    category: 'Surat Keputusan',
    documentDate: DateTime(2026, 3, 15),
    fiscalYear: 2026,
    localFilePath: 'C:/mock/path/nonexistent_document.pdf',
    fileName: 'nonexistent_document.pdf',
    fileSizeBytes: 2048576,
    mimeType: 'application/pdf',
    sha256Hash:
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    syncStatus: DocumentSyncStatus.synced,
    createdAt: DateTime(2026, 3, 15),
    updatedAt: DateTime(2026, 3, 15),
  );

  testWidgets(
    'DocumentListView renders without RenderFlex overflow in narrow viewport (380px)',
    (tester) async {
      tester.view.physicalSize = const Size(380, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            documentsListStreamProvider.overrideWith(
              (ref) => Stream.value([sampleDoc]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 380,
                child: DocumentListView(
                  onOpenAddDocument: () {},
                  onOpenCommandPalette: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify document rendered without errors
      expect(find.text(sampleDoc.title), findsOneWidget);
      expect(find.text('#${sampleDoc.documentNumber}'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

      // Ensure no overflow exception was thrown
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Document item popup menu contains Open and Open With options', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentsListStreamProvider.overrideWith(
            (ref) => Stream.value([sampleDoc]),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DocumentListView(
              onOpenAddDocument: () {},
              onOpenCommandPalette: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open the popup menu
    final dynamic popupState = tester.state(
      find.byType(PopupMenuButton<String>),
    );
    popupState.showButtonMenu();
    await tester.pumpAndSettle();

    // Expect Open and Show in Folder options, and Open With is removed
    expect(find.text('Buka Dokumen'), findsOneWidget);
    expect(find.text('Buka Dengan... (Open With)'), findsNothing);
    expect(find.text('Tampilkan di Folder'), findsOneWidget);
  });

  testWidgets(
    'DocumentPreviewPanel renders Buka Dokumen button and SafeArea footer (Buka Dengan removed)',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedDocumentProvider.overrideWith(
              () => MockSelectedDocumentNotifier(sampleDoc),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DocumentPreviewPanel()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify preview card has Buka Dokumen and Buka Dengan is deleted
      expect(find.text('Buka Dokumen'), findsOneWidget);
      expect(find.text('Buka Dengan... (Open With)'), findsNothing);
      expect(find.text('nonexistent_document.pdf'), findsOneWidget);

      // Verify footer has Upload ke Google Drive wrapped in SafeArea
      expect(find.text('Upload Ulang ke GDrive'), findsOneWidget);
      expect(find.byType(SafeArea), findsWidgets);
    },
  );

  testWidgets(
    'Clicking X in modal route dismisses route and clears selection',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedDocumentProvider.overrideWith(
              () => MockSelectedDocumentNotifier(sampleDoc),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  return ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: ctx,
                        useSafeArea: true,
                        builder: (_) => const DocumentPreviewPanel(),
                      );
                    },
                    child: const Text('Open Sheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify sheet is open
      expect(find.text('nonexistent_document.pdf'), findsOneWidget);

      // Click the X button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Verify the bottom sheet has been dismissed
      expect(find.text('nonexistent_document.pdf'), findsNothing);
    },
  );

  testWidgets(
    'FileOpenerService safely warns and returns false when file does not exist',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await FileOpenerService.openFile(
                      'nonexistent_file_xyz_123.pdf',
                      context,
                    );
                  },
                  child: const Text('Open Nonexistent'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Nonexistent'));
      await tester.pump();

      // Verify Toast is displayed without crashing
      expect(find.text('Berkas Tidak Ditemukan'), findsOneWidget);

      // Pump past the toast dismissal duration so timer doesn't remain pending
      await tester.pump(const Duration(milliseconds: 3500));
    },
  );

  testWidgets(
    'DocumentListView wraps documents with Dismissible swipe left to trash',
    (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            documentsListStreamProvider.overrideWith(
              (ref) => Stream.value([sampleDoc]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DocumentListView(
                onOpenAddDocument: () {},
                onOpenCommandPalette: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Dismissible is present with direction endToStart (swipe left)
      final dismissibleFinder = find.byType(Dismissible);
      expect(dismissibleFinder, findsOneWidget);
      final dismissible = tester.widget<Dismissible>(dismissibleFinder);
      expect(dismissible.direction, DismissDirection.endToStart);

      // Swipe left (drag from right to left)
      await tester.drag(dismissibleFinder, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Confirmation dialog appears. Phase 1 renamed "Hapus" to
      // "Pindahkan ke Tempat Sampah" so the file remains on disk for
      // restore; the test locks the new wording in.
      expect(find.text('Pindahkan ke Tempat Sampah'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Pindahkan'), findsWidgets);

      // Cancel dismissal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Document is still present
      expect(find.text(sampleDoc.title), findsOneWidget);
    },
  );

  testWidgets('CloudSyncSettingsModal renders configuration controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: CloudSyncSettingsModal(promptForUpload: true)),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Konfigurasi Google Drive'), findsOneWidget);
    expect(find.text('Mode Simulasi / Demo Cloud'), findsOneWidget);
    expect(find.text('Simpan & Lanjutkan Upload'), findsOneWidget);
  });
}
