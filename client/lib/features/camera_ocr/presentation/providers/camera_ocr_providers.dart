import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mlkit_ocr_service.dart';
import '../../domain/ocr_service.dart';

/// Provider exposing abstract IOcrService (DIP compliant).
final ocrServiceProvider = Provider<IOcrService>((ref) {
  final service = MlKitOcrService();
  ref.onDispose(() => service.dispose());
  return service;
});
