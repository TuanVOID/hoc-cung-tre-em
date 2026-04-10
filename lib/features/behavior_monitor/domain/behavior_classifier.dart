import 'dart:collection';
import 'package:hoc_cung_tre_em/core/constants/app_constants.dart';
import 'package:hoc_cung_tre_em/features/behavior_monitor/domain/models/behavior_models.dart';

/// BehaviorClassifier — Phân loại hành vi từ FaceAnalysis
///
/// Sử dụng rules-based logic + temporal smoothing để tránh false positives.
/// Ví dụ: Trẻ quay đi 1 giây rồi quay lại ngay → KHÔNG được tính là mất tập trung.
class BehaviorClassifier {
  /// Buffer lưu N frame gần nhất để smoothing
  static const int _bufferSize = 5;
  final Queue<FaceAnalysis> _buffer = Queue<FaceAnalysis>();

  /// Thời điểm mặt biến mất lần cuối
  DateTime? _faceDisappearedAt;

  /// Thời điểm mắt nhắm lần cuối
  DateTime? _eyesClosedAt;

  /// Hành vi hiện tại
  ChildBehavior _currentBehavior = ChildBehavior.focused;

  ChildBehavior get currentBehavior => _currentBehavior;

  /// Phân loại hành vi từ kết quả FaceAnalysis mới
  /// Trả về [BehaviorEvent] nếu có sự thay đổi hành vi
  BehaviorEvent? classify(FaceAnalysis analysis) {
    // Thêm vào buffer
    _buffer.addLast(analysis);
    if (_buffer.length > _bufferSize) {
      _buffer.removeFirst();
    }

    final newBehavior = _determineBehavior(analysis);
    final previousBehavior = _currentBehavior;

    _currentBehavior = newBehavior;

    // Chỉ emit event khi hành vi THAY ĐỔI
    if (newBehavior != previousBehavior) {
      return BehaviorEvent(
        behavior: newBehavior,
        timestamp: analysis.timestamp,
        faceData: analysis,
      );
    }

    return null;
  }

  /// Reset bộ phân loại (khi bắt đầu phiên học mới)
  void reset() {
    _buffer.clear();
    _faceDisappearedAt = null;
    _eyesClosedAt = null;
    _currentBehavior = ChildBehavior.focused;
  }

  // ━━━━━━━━━━━━ PRIVATE LOGIC ━━━━━━━━━━━━

  ChildBehavior _determineBehavior(FaceAnalysis analysis) {
    final now = analysis.timestamp;

    // ━━━ RULE 1: ABSENT — Không thấy mặt > 5s ━━━
    if (!analysis.faceDetected) {
      _faceDisappearedAt ??= now;
      final absentDuration = now.difference(_faceDisappearedAt!).inSeconds;

      if (absentDuration >= AppConstants.absentTimeoutSeconds) {
        return ChildBehavior.absent;
      }
      // Chưa đủ 5s → giữ nguyên trạng thái cũ (có thể chỉ ngó ra 1 giây)
      return _currentBehavior;
    }

    // Mặt đã xuất hiện lại → reset timer absent
    _faceDisappearedAt = null;

    // ━━━ RULE 2: SLEEPY — Mắt nhắm < 0.3 kéo dài > 3s ━━━
    if (analysis.averageEyeOpen < AppConstants.eyeOpenThreshold) {
      _eyesClosedAt ??= now;
      final sleepDuration = now.difference(_eyesClosedAt!).inSeconds;

      if (sleepDuration >= 3) {
        return ChildBehavior.sleepy;
      }
    } else {
      _eyesClosedAt = null;
    }

    // ━━━ RULE 3: DISTRACTED — Quay đầu > 30° (dùng temporal smoothing) ━━━
    if (_isDistractedConsistently()) {
      return ChildBehavior.distracted;
    }

    // ━━━ RULE 4: FOCUSED — Nhìn thẳng, mắt mở ━━━
    return ChildBehavior.focused;
  }

  /// Kiểm tra mất tập trung ĐỀU ĐẶN trong buffer (tránh false positive)
  /// Yêu cầu: ≥ 3/5 frame gần nhất đều có headY > threshold
  bool _isDistractedConsistently() {
    if (_buffer.length < 3) return false;

    int distractedFrames = 0;
    for (final analysis in _buffer) {
      if (!analysis.faceDetected) continue;

      final absY = analysis.headEulerAngleY.abs();
      final absX = analysis.headEulerAngleX.abs();

      if (absY > AppConstants.headRotationThreshold || absX > 25) {
        distractedFrames++;
      }
    }

    // Cần ≥ 3 frame liên tiếp bị distracted
    return distractedFrames >= 3;
  }
}
