import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:document_management/features/camera_ocr/domain/ocr_result.dart';
import 'package:document_management/features/camera_ocr/domain/ocr_service.dart';
import 'package:document_management/features/camera_ocr/presentation/providers/camera_ocr_providers.dart';

class FakeOcrService implements IOcrService {
  final OcrResult Function(File file)? onRecognize;
  bool disposed = false;

  FakeOcrService({this.onRecognize});

  @override
  Future<OcrResult> recognizeText(File imageFile) async {
    if (onRecognize != null) {
      return onRecognize!(imageFile);
    }
    return const OcrResult(
      text: 'Surat Keputusan No. 42/SK/2026',
      lines: ['Surat Keputusan', 'No. 42/SK/2026'],
      blocks: ['Surat Keputusan\nNo. 42/SK/2026'],
    );
  }

  @override
  void dispose() {
    disposed = true;
  }
}

void main() {
  group('OcrResult Value Object', () {
    test('constructs populated OcrResult correctly', () {
      const result = OcrResult(
        text: 'Laporan Keuangan Q1',
        lines: ['Laporan Keuangan', 'Q1'],
        blocks: ['Laporan Keuangan Q1'],
      );

      expect(result.text, 'Laporan Keuangan Q1');
      expect(result.lines.length, 2);
      expect(result.blocks.length, 1);
      expect(result.isNotEmpty, isTrue);
      expect(result.isEmpty, isFalse);
    });

    test('OcrResult.empty initializes with empty text and lists', () {
      const empty = OcrResult.empty();

      expect(empty.text, '');
      expect(empty.lines, isEmpty);
      expect(empty.blocks, isEmpty);
      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);
    });

    test('whitespace-only text counts as empty', () {
      const whitespace = OcrResult(text: '   \n\t  ');

      expect(whitespace.isEmpty, isTrue);
      expect(whitespace.isNotEmpty, isFalse);
    });
  });

  group('IOcrService and Riverpod DIP', () {
    test('ocrServiceProvider can be overridden with IOcrService mock', () async {
      final fakeService = FakeOcrService(
        onRecognize: (file) => OcrResult(
          text: 'Pindaian dari ${file.path}',
          lines: ['Pindaian dari ${file.path}'],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          ocrServiceProvider.overrideWithValue(fakeService),
        ],
      );

      final service = container.read(ocrServiceProvider);
      expect(service, isA<IOcrService>());

      final testFile = File('test_document.jpg');
      final result = await service.recognizeText(testFile);

      expect(result.text, 'Pindaian dari test_document.jpg');
      expect(result.isNotEmpty, isTrue);

      container.dispose();
    });
  });
}
