import 'dart:io';

import 'ocr_result.dart';

/// Abstract interface for OCR text recognition engine (ISP & DIP compliant).
abstract interface class IOcrService {
  Future<OcrResult> recognizeText(File imageFile);
  void dispose();
}
