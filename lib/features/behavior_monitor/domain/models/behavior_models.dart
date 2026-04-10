/// Phân loại hành vi của trẻ trong phiên học
enum ChildBehavior {
  /// 👀 Tập trung: Nhìn thẳng, mắt mở, tư thế ngồi đúng
  focused,

  /// 😐 Mất tập trung: Quay mặt đi, nhìn chỗ khác
  distracted,

  /// 😴 Buồn ngủ: Mắt nhắm kéo dài, gục đầu
  sleepy,

  /// ❌ Rời chỗ: Không thấy mặt trong khung hình
  absent,

  /// 🤸 Nghịch ngợm: Cử động nhiều, đứng lên ngồi xuống
  fidgeting,
}

/// Kết quả phân tích khuôn mặt từ ML Kit
class FaceAnalysis {
  /// Góc xoay đầu theo trục X (Ngẩng lên/Cúi xuống), đơn vị: độ
  final double headEulerAngleX;

  /// Góc xoay đầu theo trục Y (Quay trái/phải), đơn vị: độ
  final double headEulerAngleY;

  /// Góc xoay đầu theo trục Z (Nghiêng), đơn vị: độ
  final double headEulerAngleZ;

  /// Xác suất mắt trái đang mở (0.0 = nhắm, 1.0 = mở)
  final double leftEyeOpenProb;

  /// Xác suất mắt phải đang mở (0.0 = nhắm, 1.0 = mở)
  final double rightEyeOpenProb;

  /// Xác suất đang cười (0.0 - 1.0)
  final double smilingProb;

  /// Có phát hiện khuôn mặt trong frame không?
  final bool faceDetected;

  /// Thời điểm phân tích
  final DateTime timestamp;

  const FaceAnalysis({
    required this.headEulerAngleX,
    required this.headEulerAngleY,
    required this.headEulerAngleZ,
    required this.leftEyeOpenProb,
    required this.rightEyeOpenProb,
    required this.smilingProb,
    required this.faceDetected,
    required this.timestamp,
  });

  /// Trả về xác suất mắt mở trung bình (cả 2 mắt)
  double get averageEyeOpen => (leftEyeOpenProb + rightEyeOpenProb) / 2;

  /// Face analysis rỗng (không phát hiện mặt)
  factory FaceAnalysis.empty() => FaceAnalysis(
        headEulerAngleX: 0,
        headEulerAngleY: 0,
        headEulerAngleZ: 0,
        leftEyeOpenProb: 0,
        rightEyeOpenProb: 0,
        smilingProb: 0,
        faceDetected: false,
        timestamp: DateTime.now(),
      );

  @override
  String toString() =>
      'FaceAnalysis(detected=$faceDetected, Y=${headEulerAngleY.toStringAsFixed(1)}°, '
      'eyeOpen=${averageEyeOpen.toStringAsFixed(2)})';
}

/// Sự kiện hành vi — ghi lại mỗi lần trẻ thay đổi trạng thái
class BehaviorEvent {
  /// Loại hành vi
  final ChildBehavior behavior;

  /// Thời điểm phát hiện
  final DateTime timestamp;

  /// Thời lượng (giây) trẻ ở trạng thái này trước khi chuyển sang trạng thái khác
  final int durationSeconds;

  /// Phân tích khuôn mặt tại thời điểm phát hiện (để debug)
  final FaceAnalysis? faceData;

  const BehaviorEvent({
    required this.behavior,
    required this.timestamp,
    this.durationSeconds = 0,
    this.faceData,
  });

  @override
  String toString() =>
      'BehaviorEvent(${behavior.name}, ${durationSeconds}s, $timestamp)';
}

/// Metrics tổng hợp cho 1 phiên học
class BehaviorMetrics {
  /// Điểm tập trung (0-100%)
  final double focusScore;

  /// Số lần mất tập trung
  final int distractionCount;

  /// Tổng thời gian tập trung (giây)
  final int totalFocusSeconds;

  /// Tổng thời gian phiên học (giây)
  final int totalSessionSeconds;

  /// Lịch sử các sự kiện hành vi
  final List<BehaviorEvent> history;

  const BehaviorMetrics({
    this.focusScore = 100.0,
    this.distractionCount = 0,
    this.totalFocusSeconds = 0,
    this.totalSessionSeconds = 0,
    this.history = const [],
  });

  BehaviorMetrics copyWith({
    double? focusScore,
    int? distractionCount,
    int? totalFocusSeconds,
    int? totalSessionSeconds,
    List<BehaviorEvent>? history,
  }) {
    return BehaviorMetrics(
      focusScore: focusScore ?? this.focusScore,
      distractionCount: distractionCount ?? this.distractionCount,
      totalFocusSeconds: totalFocusSeconds ?? this.totalFocusSeconds,
      totalSessionSeconds: totalSessionSeconds ?? this.totalSessionSeconds,
      history: history ?? this.history,
    );
  }
}
