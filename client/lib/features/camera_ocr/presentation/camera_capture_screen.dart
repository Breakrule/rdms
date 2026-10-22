import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'ocr_review_screen.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.off;
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(_cameras[_selectedCameraIndex]);
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _errorMessage = 'Tidak ada sensor kamera yang terdeteksi di perangkat ini.';
          });
        }
        return;
      }

      // Default to back camera
      final backIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      _selectedCameraIndex = backIndex != -1 ? backIndex : 0;

      await _initCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('[CameraCaptureScreen] Camera init error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Gagal mengakses kamera: $e';
        });
      }
    }
  }

  Future<void> _initCameraController(CameraDescription camera) async {
    final oldController = _controller;
    if (oldController != null) {
      _controller = null;
      await oldController.dispose();
    }

    final newController = CameraController(
      camera,
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );

    try {
      await newController.initialize();
      await newController.setFlashMode(_currentFlashMode);

      if (mounted) {
        setState(() {
          _controller = newController;
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('[CameraCaptureScreen] Controller init error: $e');
      await newController.dispose();
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Gagal menyiapkan viewfinder kamera: $e';
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final nextMode = switch (_currentFlashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.torch,
      FlashMode.torch => FlashMode.off,
      _ => FlashMode.off,
    };

    try {
      await _controller!.setFlashMode(nextMode);
      if (mounted) {
        setState(() => _currentFlashMode = nextMode);
      }
    } catch (e) {
      debugPrint('[CameraCaptureScreen] Toggle flash error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isCapturing) return;

    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _selectedCameraIndex = nextIndex;
    setState(() => _isInitializing = true);
    await _initCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final xFile = await controller.takePicture();
      final capturedFile = File(xFile.path);

      if (!mounted) return;

      // Navigate to review and crop screen
      final result = await Navigator.of(context).push<OcrCaptureResult>(
        MaterialPageRoute(
          builder: (ctx) => OcrReviewScreen(initialImage: capturedFile),
        ),
      );

      // If review confirmed OCR extraction, return result back to parent
      if (result != null && mounted) {
        Navigator.of(context).pop(result);
        return;
      }
    } catch (e) {
      debugPrint('[CameraCaptureScreen] Capture photo error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  IconData _flashIcon(FlashMode mode) {
    return switch (mode) {
      FlashMode.off => Icons.flash_off_rounded,
      FlashMode.auto => Icons.flash_auto_rounded,
      FlashMode.torch => Icons.flash_on_rounded,
      _ => Icons.flash_off_rounded,
    };
  }

  String _flashTooltip(FlashMode mode) {
    return switch (mode) {
      FlashMode.off => 'Flash: Mati',
      FlashMode.auto => 'Flash: Otomatis',
      FlashMode.torch => 'Flash: Selalu Menyala',
      _ => 'Flash: Mati',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera Preview or Fallback
            _buildCameraPreview(),

            // Document Viewfinder Guide Overlay
            if (_controller != null && _controller!.value.isInitialized)
              const _DocumentFramingOverlay(),

            // Top Header Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(),
            ),

            // Bottom Shutter Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white70),
            SizedBox(height: 16),
            Text(
              'Menyiapkan kamera...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white54,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
                onPressed: _initializeCamera,
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Center(
      child: CameraPreview(controller),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Tutup',
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text(
            'Pindai Dokumen Fisik',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            tooltip: _flashTooltip(_currentFlashMode),
            icon: Icon(
              _flashIcon(_currentFlashMode),
              color: _currentFlashMode != FlashMode.off
                  ? Colors.amberAccent
                  : Colors.white,
            ),
            onPressed: _controller?.value.isInitialized == true
                ? _toggleFlash
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Switch camera lens button
          if (_cameras.length > 1)
            IconButton(
              tooltip: 'Ganti Kamera',
              iconSize: 28,
              icon: const Icon(
                Icons.flip_camera_ios_rounded,
                color: Colors.white,
              ),
              onPressed: _isCapturing ? null : _switchCamera,
            )
          else
            const SizedBox(width: 48),

          // Central Shutter Button
          GestureDetector(
            onTap: _isCapturing ? null : _capturePhoto,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                color: Colors.transparent,
              ),
              child: Center(
                child: _isCapturing
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),

          // Balance layout spacer
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Viewfinder overlay with corner guides for framing documents.
class _DocumentFramingOverlay extends StatelessWidget {
  const _DocumentFramingOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1 / 1.414, // A4 document proportion
                  child: Stack(
                    children: [
                      // Framing rectangle outline
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                      ),
                      // Corner accent indicators
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _buildCorner(isTop: true, isLeft: true),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _buildCorner(isTop: true, isLeft: false),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: _buildCorner(isTop: false, isLeft: true),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _buildCorner(isTop: false, isLeft: false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
                child: const Text(
                  'Arahkan dokumen ke dalam bingkai & pastikan teks terbaca',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    const length = 24.0;
    const thickness = 3.5;
    const color = Color(0xFF0F52BA);

    return SizedBox(
      width: length,
      height: length,
      child: CustomPaint(
        painter: _CornerPainter(
          isTop: isTop,
          isLeft: isLeft,
          thickness: thickness,
          color: color,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;
  final double thickness;
  final Color color;

  _CornerPainter({
    required this.isTop,
    required this.isLeft,
    required this.thickness,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isTop && isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.isTop != isTop ||
      oldDelegate.isLeft != isLeft ||
      oldDelegate.thickness != thickness ||
      oldDelegate.color != color;
}
