import 'package:flutter/foundation.dart';

/// Voice Profile — Dữ liệu giọng nói đã clone
class VoiceProfile {
  /// ID duy nhất
  final String id;

  /// Nhãn: "Mẹ", "Bố", "Ông", "Bà"
  final String label;

  /// Voice embedding (vector) — lưu trữ compressed
  final Uint8List? embedding;

  /// Thời điểm tạo
  final DateTime createdAt;

  /// File size (bytes)
  final int sizeBytes;

  const VoiceProfile({
    required this.id,
    required this.label,
    this.embedding,
    required this.createdAt,
    this.sizeBytes = 0,
  });
}

/// VoiceCloneService — Interface cho Pocket-TTS voice cloning
///
/// ⚠️ PLACEHOLDER — Sẽ implement khi có native Kotlin bridge
///
/// Flow: Record 5s → Extract embedding → Save profile → Synthesize
/// Pocket-TTS: ~100MB model, CPU-only, MIT license
abstract class VoiceCloneService {
  /// Check thiết bị có đủ RAM cho voice clone không (>= 4GB)
  Future<bool> isDeviceCapable();

  /// Check model đã download chưa (~100MB)
  Future<bool> isModelReady();

  /// Download Pocket-TTS model
  Future<void> downloadModel({
    void Function(double progress)? onProgress,
  });

  /// Enroll giọng nói từ recording 5-10s
  Future<VoiceProfile> enrollVoice({
    required Uint8List audioSample,
    required String label,
  });

  /// Synthesize text → audio dùng voice profile
  Future<Uint8List> synthesize({
    required String text,
    required VoiceProfile voice,
    double speed = 1.0,
    double pitch = 1.0,
  });

  /// Lấy danh sách profiles đã lưu
  Future<List<VoiceProfile>> getSavedProfiles();

  /// Xóa profile
  Future<void> deleteProfile(String id);
}

/// Placeholder implementation — chỉ có stub, chưa chạy thật
class VoiceCloneServiceStub implements VoiceCloneService {
  @override
  Future<bool> isDeviceCapable() async {
    debugPrint('VoiceClone: Checking device capability (stub)');
    return false; // Placeholder: luôn trả false để dùng Google TTS
  }

  @override
  Future<bool> isModelReady() async => false;

  @override
  Future<void> downloadModel({
    void Function(double progress)? onProgress,
  }) async {
    throw UnimplementedError(
      'Pocket-TTS model download chưa được implement. '
      'Cần native Kotlin bridge (PocketTtsPlugin.kt).',
    );
  }

  @override
  Future<VoiceProfile> enrollVoice({
    required Uint8List audioSample,
    required String label,
  }) async {
    throw UnimplementedError('Voice enrollment chưa available');
  }

  @override
  Future<Uint8List> synthesize({
    required String text,
    required VoiceProfile voice,
    double speed = 1.0,
    double pitch = 1.0,
  }) async {
    throw UnimplementedError('Voice synthesis chưa available');
  }

  @override
  Future<List<VoiceProfile>> getSavedProfiles() async => [];

  @override
  Future<void> deleteProfile(String id) async {}
}
