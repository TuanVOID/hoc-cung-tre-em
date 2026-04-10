import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hoc_cung_tre_em/features/behavior_monitor/domain/models/behavior_models.dart';

/// FaceAnalyzer — Chuyển đổi CameraImage → FaceAnalysis
/// Sử dụng Google ML Kit Face Detection, chạy 100% on-device
class FaceAnalyzer {
  late final FaceDetector _faceDetector;

  FaceAnalyzer() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableClassification: true, // Smile, Eye open probability
        enableTracking: true,       // Track face ID qua các frames
        enableLandmarks: true,      // Detect mắt, mũi, miệng
      ),
    );
  }

  /// Phân tích khuôn mặt từ CameraImage
  /// Trả về [FaceAnalysis] chứa góc xoay đầu, trạng thái mắt, v.v.
  Future<FaceAnalysis> analyze(CameraImage image, CameraDescription camera) async {
    final inputImage = _convertToInputImage(image, camera);

    if (inputImage == null) {
      return FaceAnalysis.empty();
    }

    try {
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return FaceAnalysis(
          headEulerAngleX: 0,
          headEulerAngleY: 0,
          headEulerAngleZ: 0,
          leftEyeOpenProb: 0,
          rightEyeOpenProb: 0,
          smilingProb: 0,
          faceDetected: false,
          timestamp: DateTime.now(),
        );
      }

      // Lấy khuôn mặt đầu tiên (giả định chỉ có 1 trẻ / 1 frame)
      final face = faces.first;

      return FaceAnalysis(
        headEulerAngleX: face.headEulerAngleX ?? 0,
        headEulerAngleY: face.headEulerAngleY ?? 0,
        headEulerAngleZ: face.headEulerAngleZ ?? 0,
        leftEyeOpenProb: face.leftEyeOpenProbability ?? 0.5,
        rightEyeOpenProb: face.rightEyeOpenProbability ?? 0.5,
        smilingProb: face.smilingProbability ?? 0,
        faceDetected: true,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('FaceAnalyzer: Error processing image: $e');
      return FaceAnalysis.empty();
    }
  }

  /// Giải phóng tài nguyên ML Kit
  void dispose() {
    _faceDetector.close();
  }

  // ━━━━━━━━━━━━ PRIVATE: Convert CameraImage → InputImage ━━━━━━━━━━━━

  InputImage? _convertToInputImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    // Xác định rotation dựa trên sensor orientation của camera
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    // Trên Android, sensorOrientation là góc cần xoay để ảnh đúng chiều
    switch (sensorOrientation) {
      case 0:
        rotation = InputImageRotation.rotation0deg;
        break;
      case 90:
        rotation = InputImageRotation.rotation90deg;
        break;
      case 180:
        rotation = InputImageRotation.rotation180deg;
        break;
      case 270:
        rotation = InputImageRotation.rotation270deg;
        break;
      default:
        rotation = InputImageRotation.rotation0deg;
    }

    // Chuyển đổi format ảnh
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) {
      debugPrint('FaceAnalyzer: Unsupported image format: ${image.format.raw}');
      return null;
    }

    // Ghép các planes thành 1 buffer cho NV21 format
    final allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }
}
