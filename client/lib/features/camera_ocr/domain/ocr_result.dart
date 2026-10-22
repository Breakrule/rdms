/// Value object representing text recognized from an image by OCR.
class OcrResult {
  final String text;
  final List<String> lines;
  final List<String> blocks;

  const OcrResult({
    required this.text,
    this.lines = const [],
    this.blocks = const [],
  });

  const OcrResult.empty()
      : text = '',
        lines = const [],
        blocks = const [];

  bool get isEmpty => text.trim().isEmpty;
  bool get isNotEmpty => text.trim().isNotEmpty;
}
