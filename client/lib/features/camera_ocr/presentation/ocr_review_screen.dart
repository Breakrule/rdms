import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import 'providers/camera_ocr_providers.dart';

class OcrCaptureResult {
  final File file;
  final String extractedText;

  const OcrCaptureResult({
    required this.file,
    required this.extractedText,
  });
}

class OcrReviewScreen extends ConsumerStatefulWidget {
  final File initialImage;

  const OcrReviewScreen({super.key, required this.initialImage});

  @override
  ConsumerState<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends ConsumerState<OcrReviewScreen> {
  late File _currentImage;
  final _textController = TextEditingController();
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.initialImage;
    _runOcr();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _runOcr() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final ocrService = ref.read(ocrServiceProvider);
      final result = await ocrService.recognizeText(_currentImage);

      if (mounted) {
        setState(() {
          _textController.text = result.text;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '$e';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _cropImage() async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: _currentImage.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Potong Dokumen',
            toolbarColor: const Color(0xFF0F52BA),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Potong Dokumen',
          ),
        ],
      );

      if (cropped != null) {
        setState(() {
          _currentImage = File(cropped.path);
        });
        await _runOcr();
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          title: 'Gagal Memotong Gambar',
          message: '$e',
          type: ToastType.error,
        );
      }
    }
  }

  void _confirmAndReturn() {
    final result = OcrCaptureResult(
      file: _currentImage,
      extractedText: _textController.text.trim(),
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tinjau Hasil Pindai & OCR'),
        actions: [
          IconButton(
            tooltip: 'Potong Gambar',
            icon: const Icon(Icons.crop_rounded),
            onPressed: _cropImage,
          ),
          IconButton(
            tooltip: 'Pindai Ulang OCR',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _runOcr,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Preview Bar (Image Thumbnail + Stats)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _currentImage,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.document_scanner_rounded,
                              size: 16,
                              color: Color(0xFF0F52BA),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Hasil Pindai Dokumen',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isProcessing
                              ? 'Menganalisis teks dengan on-device ML Kit...'
                              : (_errorMessage != null
                                  ? 'Gagal mengenali teks'
                                  : '${_textController.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} kata terdeteksi'),
                          style: TextStyle(
                            fontSize: 12,
                            color: _errorMessage != null
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.crop_rounded, size: 14),
                    label: const Text('Potong'),
                    onPressed: _cropImage,
                  ),
                ],
              ),
            ),

            // Content Area: State Machine (Processing / Error / Text Editor)
            Expanded(
              child: _isProcessing
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Memindai teks dokumen...',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Menggunakan on-device AI offline',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Gagal Memproses OCR',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Coba Lagi'),
                                  onPressed: _runOcr,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.edit_note_rounded,
                                    size: 18,
                                    color: Color(0xFF0F52BA),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Kutipan Teks Hasil OCR (Dapat Diedit)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_textController.text.isNotEmpty)
                                    TextButton.icon(
                                      icon: const Icon(Icons.copy_rounded, size: 14),
                                      label: const Text('Salin'),
                                      onPressed: () {
                                        // copy to clipboard if needed
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: TextField(
                                  controller: _textController,
                                  maxLines: null,
                                  expands: true,
                                  textAlignVertical: TextAlignVertical.top,
                                  style: const TextStyle(fontSize: 13, height: 1.5),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Tidak ada teks terdeteksi. Ketik atau koreksi teks di sini...',
                                    filled: true,
                                    fillColor: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusControl,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.all(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Gunakan Dokumen Ini'),
                      onPressed: _isProcessing ? null : _confirmAndReturn,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
