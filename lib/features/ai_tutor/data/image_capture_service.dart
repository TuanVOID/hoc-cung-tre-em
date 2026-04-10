import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// ImageCaptureService — Chụp ảnh sách từ camera hoặc chọn từ gallery
class ImageCaptureService {
  ImageCaptureService._();
  static final ImageCaptureService instance = ImageCaptureService._();

  final ImagePicker _picker = ImagePicker();
  CameraController? _controller;
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  // ━━━━━━━━━━━━ CAMERA MODE ━━━━━━━━━━━━

  /// Khởi tạo camera cho chụp ảnh sách (camera SAU, high-res)
  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('Không tìm thấy camera');
    }

    // Dùng camera sau cho chụp sách (chất lượng cao hơn)
    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.high, // High-res cho OCR chính xác
      enableAudio: false,
    );

    await _controller!.initialize();

    // Bật autofocus
    await _controller!.setFocusMode(FocusMode.auto);
    await _controller!.setExposureMode(ExposureMode.auto);

    _isInitialized = true;
    debugPrint('ImageCapture: Camera initialized (${_controller!.value.previewSize})');
  }

  /// Chụp ảnh từ camera
  Future<XFile?> capturePhoto() async {
    if (_controller == null || !_isInitialized) return null;

    try {
      final photo = await _controller!.takePicture();
      debugPrint('ImageCapture: Photo captured → ${photo.path}');
      return photo;
    } catch (e) {
      debugPrint('ImageCapture: Capture error → $e');
      return null;
    }
  }

  /// Bật/tắt flash
  Future<void> toggleFlash() async {
    if (_controller == null) return;

    final currentMode = _controller!.value.flashMode;
    final newMode =
        currentMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _controller!.setFlashMode(newMode);
    debugPrint('ImageCapture: Flash → ${newMode.name}');
  }

  /// Giải phóng camera
  Future<void> disposeCamera() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  // ━━━━━━━━━━━━ GALLERY MODE ━━━━━━━━━━━━

  /// Chọn ảnh từ gallery
  Future<XFile?> pickFromGallery() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (photo != null) {
        debugPrint('ImageCapture: Gallery picked → ${photo.path}');
      }
      return photo;
    } catch (e) {
      debugPrint('ImageCapture: Gallery pick error → $e');
      return null;
    }
  }
}
