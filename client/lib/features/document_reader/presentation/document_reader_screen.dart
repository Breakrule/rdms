import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../../../../core/services/file_opener_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../documents/domain/models/document_item.dart';

/// Phase 5.1 bounded embedded reader.
///
/// Scope on purpose (the plan's dependency gate):
/// * PDF is rendered with `flutter_pdfview` (MIT, offline, native).
/// * Images are shown with pinch-zoom + rotate using Flutter itself.
/// * Everything else (Office, etc.) is NOT rendered here — callers keep using
///   the external opener, and this reader is only offered on Android/iOS
///   because the plugin does not support desktop/web (unsupported platform
///   actions are hidden, not broken).
///
/// The reader is deliberately a separate surface from the metadata details
/// panel; it shows the document, not its record.
class DocumentReaderScreen extends StatefulWidget {
  final DocumentItem doc;

  const DocumentReaderScreen({super.key, required this.doc});

  static bool _isPdf(DocumentItem doc) =>
      doc.mimeType == 'application/pdf' ||
      doc.fileName.toLowerCase().endsWith('.pdf');

  static bool _isImage(DocumentItem doc) =>
      doc.mimeType.startsWith('image/') ||
      const {'.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp'}
          .contains(_ext(doc.fileName));

  /// Whether the in-app reader can show this document on the current
  /// platform. False on desktop/web and for non-PDF/image types, so the
  /// caller falls back to external opening instead of a broken viewer.
  static bool isAvailable(DocumentItem doc) =>
      (Platform.isAndroid || Platform.isIOS) &&
      (_isPdf(doc) || _isImage(doc));

  static String _ext(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot).toLowerCase();
  }

  static Future<void> open(BuildContext context, DocumentItem doc) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DocumentReaderScreen(doc: doc)),
    );
  }

  @override
  State<DocumentReaderScreen> createState() => _DocumentReaderScreenState();
}

class _DocumentReaderScreenState extends State<DocumentReaderScreen> {
  String? _loadError;
  bool _ready = false;
  int _rotationSteps = 0; // images: 0..3, each = 90 degrees

  bool get _isImage => DocumentReaderScreen._isImage(widget.doc);

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _loadError = null;
    _ready = false;
  }

  Future<void> _promptPasswordAndReload() async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dokumen Terkata Sandi'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Kata sandi PDF'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Buka'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null || !mounted) return;
    setState(() {
      _password = password;
      _reset();
      // Force the native view to rebuild with the new password.
      _pdfGeneration++;
    });
  }

  String? _password;
  int _pdfGeneration = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = File(widget.doc.localFilePath);
    final missing = !file.existsSync();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.doc.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_isImage && !missing)
            IconButton(
              tooltip: 'Putar',
              icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
              onPressed: () =>
                  setState(() => _rotationSteps = (_rotationSteps + 1) % 4),
            ),
          IconButton(
            tooltip: 'Buka di aplikasi eksternal',
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () =>
                FileOpenerService.openFile(widget.doc.localFilePath, context),
          ),
        ],
      ),
      body: missing
          ? _ErrorState(
              icon: Icons.broken_image_outlined,
              message:
                  'Berkas fisik tidak ditemukan di perangkat.\n${widget.doc.localFilePath}',
            )
          : _isImage
              ? _buildImage()
              : _buildPdf(theme),
    );
  }

  Widget _buildImage() {
    return GestureDetector(
      onDoubleTap: () => setState(() => _rotationSteps = (_rotationSteps + 1) % 4),
      child: Center(
        child: InteractiveViewer(
          maxScale: 6,
          child: Transform.rotate(
            angle: _rotationSteps * math.pi / 2,
            child: Image.file(
              File(widget.doc.localFilePath),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const _ErrorState(
                icon: Icons.image_not_supported_outlined,
                message: 'Gambar tidak dapat ditampilkan (rusak atau format '
                    'tidak didukung).',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdf(ThemeData theme) {
    if (_loadError != null) {
      return _ErrorState(
        icon: Icons.picture_as_pdf_outlined,
        message: _loadError!,
        action: _loadError!.toLowerCase().contains('sand') ||
                _loadError!.toLowerCase().contains('password')
            ? FilledButton.icon(
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Masukkan kata sandi'),
                onPressed: _promptPasswordAndReload,
              )
            : OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
                onPressed: () => setState(_reset),
              ),
      );
    }
    return Stack(
      children: [
        PDFView(
          key: ValueKey('pdf-${widget.doc.id}-$_pdfGeneration'),
          filePath: widget.doc.localFilePath,
          password: _password,
          autoSpacing: true,
          swipeHorizontal: false,
          nightMode: theme.brightness == Brightness.dark,
          onRender: (pages) {
            if (mounted) setState(() => _ready = pages != null && pages > 0);
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _loadError = 'PDF tidak dapat dimuat. '
                    'Mungkin rusak atau dilindungi kata sandi.';
              });
            }
          },
          onPageError: (page, error) {
            if (mounted) {
              setState(() => _loadError = 'Halaman $page gagal dimuat.');
            }
          },
        ),
        if (!_ready)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _ErrorState({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: AppTheme.space16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (action != null) ...[
              const SizedBox(height: AppTheme.space16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
