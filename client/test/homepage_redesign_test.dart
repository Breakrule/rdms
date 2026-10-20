import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:document_management/main.dart';
import 'package:document_management/features/document_explorer/presentation/document_explorer_screen.dart';
import 'package:document_management/features/documents/domain/models/document_item.dart';
import 'package:document_management/features/documents/presentation/providers/document_providers.dart';
import 'package:document_management/features/document_explorer/presentation/widgets/home_header.dart';
import 'package:document_management/features/documents/presentation/widgets/document_toolbar.dart';
import 'package:document_management/features/documents/presentation/widgets/sync_status_badge.dart';

void main() {
  final sampleDoc = DocumentItem(
    id: 'test-doc-1',
    title: 'Surat Keputusan Reformasi Birokrasi',
    documentNumber: '800/142/SK/2026',
    category: 'Surat Keputusan',
    documentDate: DateTime(2026, 3, 15),
    fiscalYear: 2026,
    localFilePath: 'C:/mock/path/sample.pdf',
    fileName: 'sample.pdf',
    fileSizeBytes: 2048576,
    mimeType: 'application/pdf',
    sha256Hash:
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    syncStatus: DocumentSyncStatus.synced,
    createdAt: DateTime(2026, 3, 15),
    updatedAt: DateTime(2026, 3, 15),
  );

  group('Responsive Layout Breakpoints', () {
    testWidgets(
      '320x568 (compact mobile) renders stacked layout, FAB import, no overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              documentsListStreamProvider.overrideWith(
                (ref) => Stream.value([sampleDoc]),
              ),
            ],
            child: const DocumentManagementApp(home: DocumentExplorerScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('Pusat Dokumen'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '390x844 (standard mobile) renders drawer menu and no horizontal overflow',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              documentsListStreamProvider.overrideWith(
                (ref) => Stream.value([sampleDoc]),
              ),
            ],
            child: const DocumentManagementApp(home: DocumentExplorerScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
        expect(find.text('Pusat Dokumen'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '600x800 (small tablet) renders drawer without permanent sidebar',
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
            child: const DocumentManagementApp(home: DocumentExplorerScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
        expect(find.text('KATEGORI DOKUMEN'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '1024x768 (desktop threshold) renders 240px sidebar and header action',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              documentsListStreamProvider.overrideWith(
                (ref) => Stream.value([sampleDoc]),
              ),
            ],
            child: const DocumentManagementApp(home: DocumentExplorerScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('RDMS'), findsOneWidget);
        expect(find.text('KATEGORI DOKUMEN'), findsOneWidget);
        expect(find.text('Tambah Dokumen'), findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '1440x900 (wide desktop) renders inline detail panel when document is selected',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              documentsListStreamProvider.overrideWith(
                (ref) => Stream.value([sampleDoc]),
              ),
              allDocumentsStreamProvider.overrideWith(
                (ref) => Stream.value([sampleDoc]),
              ),
            ],
            child: const DocumentManagementApp(home: DocumentExplorerScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Select document
        final container = ProviderScope.containerOf(
          tester.element(find.byType(DocumentExplorerScreen)),
        );
        container.read(selectedDocumentProvider.notifier).select(sampleDoc);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify inline panel is visible
        expect(find.text('Buka Dokumen'), findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);

        // Tap close button in inline panel
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Selection is cleared and panel is closed
        expect(container.read(selectedDocumentProvider), isNull);
        expect(find.text('Buka Dokumen'), findsNothing);
      },
    );
  });

  group('Text Scale Resilience', () {
    testWidgets('Scale 1.3 renders cleanly without overflow', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      tester.view.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            documentsListStreamProvider.overrideWith(
              (ref) => Stream.value([sampleDoc]),
            ),
          ],
          child: const DocumentManagementApp(home: DocumentExplorerScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Scale 2.0 renders large text without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.view.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            documentsListStreamProvider.overrideWith(
              (ref) => Stream.value([sampleDoc]),
            ),
          ],
          child: const DocumentManagementApp(home: DocumentExplorerScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });
  });

  group('Search input synchronization', () {
    testWidgets(
      'Entering query and clicking clear button synchronizes controller and state',
      (tester) async {
        final searchFocus = FocusNode();
        addTearDown(searchFocus.dispose);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: DocumentToolbar(
                  searchFocusNode: searchFocus,
                  onOpenCommandPalette: () {},
                  visibleCount: 1,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);

        // Enter query
        await tester.enterText(searchField, 'reformasi');
        await tester.pump(const Duration(milliseconds: 400));

        final container = ProviderScope.containerOf(
          tester.element(find.byType(DocumentToolbar)),
        );
        expect(container.read(documentFilterProvider).searchQuery, 'reformasi');

        // Clear button is visible
        final clearButton = find.byTooltip('Hapus Pencarian');
        expect(clearButton, findsOneWidget);

        // Tap clear button
        await tester.tap(clearButton);
        await tester.pump(const Duration(milliseconds: 100));

        expect(container.read(documentFilterProvider).searchQuery, '');
        final textFieldWidget = tester.widget<TextField>(searchField);
        expect(textFieldWidget.controller?.text, '');
      },
    );
  });

  group('Indonesian Status Badge Labels', () {
    testWidgets('Renders all Indonesian status labels accurately', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SyncStatusBadge(status: DocumentSyncStatus.localOnly),
                SyncStatusBadge(status: DocumentSyncStatus.queued),
                SyncStatusBadge(status: DocumentSyncStatus.syncing),
                SyncStatusBadge(status: DocumentSyncStatus.synced),
                SyncStatusBadge(status: DocumentSyncStatus.error),
                SyncStatusBadge(status: DocumentSyncStatus.deleted),
                SyncStatusBadge(status: DocumentSyncStatus.lost),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Lokal Saja'), findsOneWidget);
      expect(find.text('Dalam Antrean'), findsOneWidget);
      expect(find.text('Mengunggah'), findsOneWidget);
      expect(find.text('Tersimpan di Drive'), findsOneWidget);
      expect(find.text('Gagal Mengunggah'), findsOneWidget);
      expect(find.text('Dihapus di Drive'), findsOneWidget);
      expect(find.text('Nama Berubah di Drive'), findsOneWidget);
    });
  });

  group('Android Overlay / Status Bar SafeArea', () {
    testWidgets('HomeHeader title is pushed below Android status bar inset', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 48, bottom: 34);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetPadding();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HomeHeader(
                onOpenAddDocument: () {},
                onTriggerBulkUpload: () {},
                onOpenCloudSettings: () {},
                onOpenDrawer: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleTop = tester.getTopLeft(find.text('Pusat Dokumen')).dy;
      // Title must be strictly positioned below the 48.0dp Android status bar overlay
      expect(titleTop, greaterThanOrEqualTo(48.0));
    });
  });
}
