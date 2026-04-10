import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// CameraService — Singleton quản lý camera lifecycle
/// Hỗ trợ camera trước & sau, default: camera sau (trẻ không nhìn màn hình)
class CameraService {
  CameraService._();
  static final CameraService instance = CameraService._();

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;

  /// Camera đang dùng: true = SAU (default), false = TRƯỚC
  bool _useBackCamera = true;

  // ━━━━━━━━━━━━ PUBLIC GETTERS ━━━━━━━━━━━━

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isUsingBackCamera => _useBackCamera;
  bool get isProcessing => _isProcessing;

  // ━━━━━━━━━━━━ LIFECYCLE ━━━━━━━━━━━━

  /// Khởi tạo camera — gọi 1 lần khi mở phiên học
  Future<void> initialize({bool useBackCamera = true}) async {
    _useBackCamera = useBackCamera;
    _cameras = await availableCameras();

    if (_cameras.isEmpty) {
      throw CameraException('NO_CAMERA', 'Không tìm thấy camera trên thiết bị');
    }

    await _startCamera();
  }

  /// Đổi camera (trước ↔ sau) — Quick-switch khi đang học
  Future<void> switchCamera() async {
    _useBackCamera = !_useBackCamera;
    await _stopCamera();
    await _startCamera();
  }

  /// Dừng camera + giải phóng tài nguyên
  Future<void> dispose() async {
    await _stopCamera();
    _isInitialized = false;
  }

  // ━━━━━━━━━━━━ IMAGE STREAM ━━━━━━━━━━━━

  /// Bắt đầu nhận stream ảnh (cho ML Kit xử lý)
  /// [onImage] được gọi mỗi frame (10 fps)
  Future<void> startImageStream(
    void Function(CameraImage image) onImage,
  ) async {
    if (_controller == null || !_isInitialized) return;

    await _controller!.startImageStream((CameraImage image) {
      // Throttle: bỏ frame nếu đang xử lý frame trước
      if (_isProcessing) return;
      _isProcessing = true;

      onImage(image);

      // Reset flag sau khi xử lý xong (caller phải gọi markProcessingDone())
    });
  }

  /// Dừng stream ảnh
  Future<void> stopImageStream() async {
    if (_controller == null || !_isInitialized) return;
    try {
      await _controller!.stopImageStream();
    } catch (e) {
      debugPrint('CameraService: Error stopping stream: $e');
    }
  }

  /// Đánh dấu đã xử lý xong frame hiện tại (cho frame tiếp theo vào)
  void markProcessingDone() {
    _isProcessing = false;
  }

  // ━━━━━━━━━━━━ PRIVATE ━━━━━━━━━━━━

  Future<void> _startCamera() async {
    final cameraDescription = _findCamera();

    _controller = CameraController(
      cameraDescription,
      // 640x480 đủ cho face detection, tiết kiệm pin
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21, // Tối ưu cho ML Kit Android
    );

    try {
      await _controller!.initialize();
      _isInitialized = true;
      debugPrint(
        'CameraService: Initialized ${_useBackCamera ? "BACK" : "FRONT"} camera '
        '(${_controller!.value.previewSize})',
      );
    } catch (e) {
      _isInitialized = false;
      debugPrint('CameraService: Failed to initialize camera: $e');
      rethrow;
    }
  }

  Future<void> _stopCamera() async {
    if (_controller != null) {
      try {
        if (_controller!.value.isStreamingImages) {
          await _controller!.stopImageStream();
        }
        await _controller!.dispose();
      } catch (e) {
        debugPrint('CameraService: Error disposing camera: $e');
      }
      _controller = null;
    }
  }

  CameraDescription _findCamera() {
    final targetLensDirection =
        _useBackCamera ? CameraLensDirection.back : CameraLensDirection.front;

    try {
      return _cameras.firstWhere(
        (camera) => camera.lensDirection == targetLensDirection,
      );
    } catch (_) {
      // Fallback: dùng camera đầu tiên có sẵn
      debugPrint(
        'CameraService: ${targetLensDirection.name} camera not found, using first available',
      );
      return _cameras.first;
    }
  }
}
