import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../domain/ocr_result.dart';
import '../domain/ocr_service.dart';

/// Concrete on-device OCR engine utilizing Google ML Kit Text Recognition.
class MlKitOcrService implements IOcrService {
  final TextRecognizer _recognizer;

  MlKitOcrService({TextRecognizer? recognizer})
      : _recognizer =
            recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<OcrResult> recognizeText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _recognizer.processImage(inputImage);

    final blocks = <String>[];
    final lines = <String>[];

    for (final block in recognizedText.blocks) {
      blocks.add(block.text);
      for (final line in block.lines) {
        lines.add(line.text);
      }
    }

    return OcrResult(
      text: recognizedText.text,
      lines: lines,
      blocks: blocks,
    );
  }

  @override
  void dispose() {
    _recognizer.close();
  }
}
