import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoc_cung_tre_em/app/theme.dart';
import 'package:hoc_cung_tre_em/features/ai_tutor/data/image_capture_service.dart';
import 'package:hoc_cung_tre_em/features/ai_tutor/data/ocr_service.dart';
import 'package:hoc_cung_tre_em/features/ai_tutor/domain/models/ocr_result.dart';
import 'package:hoc_cung_tre_em/features/ai_tutor/presentation/widgets/ocr_preview.dart';

/// Trạng thái của Capture Screen
enum CaptureStep {
  camera,   // Chụp ảnh
  processing, // Đang xử lý OCR
  preview,  // Xem kết quả OCR
}

/// CaptureScreen — Chụp ảnh sách giáo khoa + OCR
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _capture = ImageCaptureService.instance;
  final _ocr = OcrService();

  CaptureStep _step = CaptureStep.camera;
  OcrResult? _ocrResult;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      await _capture.initializeCamera();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('CaptureScreen: Camera init error → $e');
    }
  }

  @override
  void dispose() {
    _capture.disposeCamera();
    _ocr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: switch (_step) {
          CaptureStep.camera => _buildCameraView(context),
          CaptureStep.processing => _buildProcessingView(context),
          CaptureStep.preview => _buildPreviewView(context),
        },
      ),
    );
  }

  // ━━━━━━ CAMERA VIEW ━━━━━━

  Widget _buildCameraView(BuildContext context) {
    return Stack(
      children: [
        // Camera preview (full screen)
        if (_capture.isInitialized && _capture.controller != null)
          Positioned.fill(
            child: CameraPreview(_capture.controller!),
          )
        else
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),

        // Overlay guide (vùng chụp sách)
        Positioned.fill(
          child: CustomPaint(
            painter: _BookOverlayPainter(),
          ),
        ),

        // Top bar
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
              // Hướng dẫn
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Text(
                  'Đưa sách vào khung hình 📖',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              // Flash toggle
              IconButton(
                onPressed: () async {
                  await _capture.toggleFlash();
                  if (mounted) setState(() {});
                },
                icon: Icon(
                  _capture.controller?.value.flashMode == FlashMode.torch
                      ? Icons.flash_on
                      : Icons.flash_off,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),

        // Bottom buttons
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery pick
              _circleButton(
                icon: Icons.photo_library_outlined,
                onTap: _pickFromGallery,
              ),
              // Capture button (lớn ở giữa)
              GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Placeholder cho symmetry
              const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  // ━━━━━━ PROCESSING VIEW ━━━━━━

  Widget _buildProcessingView(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppTheme.spaceSm),
            Text(
              'Đang nhận diện chữ... 📝',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: AppTheme.spaceXs),
            Text(
              'Chờ một chút nhé!',
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ━━━━━━ PREVIEW VIEW ━━━━━━

  Widget _buildPreviewView(BuildContext context) {
    if (_ocrResult == null) {
      return const Center(child: Text('Không có kết quả'));
    }

    return OcrPreview(
      result: _ocrResult!,
      imagePath: _capturedImage?.path,
      onRetake: () {
        setState(() {
          _step = CaptureStep.camera;
          _ocrResult = null;
          _capturedImage = null;
        });
      },
      onAskTutor: (text) {
        // TODO: Navigate to AI Tutor (Phase 06)
        // context.push('/tutor', extra: text);
        Navigator.of(context).pop(text);
      },
    );
  }

  // ━━━━━━ ACTIONS ━━━━━━

  Future<void> _takePhoto() async {
    final photo = await _capture.capturePhoto();
    if (photo != null) {
      _processImage(photo);
    }
  }

  Future<void> _pickFromGallery() async {
    final photo = await _capture.pickFromGallery();
    if (photo != null) {
      _processImage(photo);
    }
  }

  Future<void> _processImage(XFile photo) async {
    setState(() {
      _step = CaptureStep.processing;
      _capturedImage = photo;
    });

    final result = await _ocr.processXFile(photo);

    if (mounted) {
      setState(() {
        _ocrResult = result;
        _step = CaptureStep.preview;
      });
    }
  }
}

/// Overlay painter — vẽ khung hướng dẫn chụp sách
class _BookOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Vẽ khung hướng dẫn (vùng sách)
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.85,
      height: size.height * 0.55,
    );

    // Vẽ 4 góc rounded
    const cornerLength = 30.0;
    const radius = 12.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + cornerLength)
        ..lineTo(rect.left, rect.top + radius)
        ..arcToPoint(Offset(rect.left + radius, rect.top),
            radius: const Radius.circular(radius))
        ..lineTo(rect.left + cornerLength, rect.top),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLength, rect.top)
        ..lineTo(rect.right - radius, rect.top)
        ..arcToPoint(Offset(rect.right, rect.top + radius),
            radius: const Radius.circular(radius))
        ..lineTo(rect.right, rect.top + cornerLength),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - cornerLength)
        ..lineTo(rect.left, rect.bottom - radius)
        ..arcToPoint(Offset(rect.left + radius, rect.bottom),
            radius: const Radius.circular(radius))
        ..lineTo(rect.left + cornerLength, rect.bottom),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLength, rect.bottom)
        ..lineTo(rect.right - radius, rect.bottom)
        ..arcToPoint(Offset(rect.right, rect.bottom - radius),
            radius: const Radius.circular(radius))
        ..lineTo(rect.right, rect.bottom - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
