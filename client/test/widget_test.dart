import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:document_management/main.dart';

import 'package:document_management/features/document_explorer/presentation/document_explorer_screen.dart';
import 'package:document_management/features/splash/presentation/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders animated logo and title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(navDelay: Duration(milliseconds: 300)),
        ),
      ),
    );

    // Initial frame
    await tester.pump();
    expect(find.text('RDMS ULTIMATE'), findsOneWidget);
    expect(find.text('Smart Document Management System'), findsOneWidget);

    // Complete splash timer and transition
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(DocumentExplorerScreen), findsOneWidget);
  });

  testWidgets(
    'Renders desktop layout with sidebar and header actions when width >= 1024',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: DocumentManagementApp(home: DocumentExplorerScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('RDMS'), findsOneWidget);
      expect(find.text('Pusat Dokumen'), findsOneWidget);
      expect(find.text('Tambah Dokumen'), findsOneWidget);
      expect(find.text('Unggah Semua'), findsOneWidget);
    },
  );

  testWidgets('Renders adaptive mobile/tablet layout when width < 1024', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: DocumentManagementApp(home: DocumentExplorerScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Pusat Dokumen'), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
  });
}
