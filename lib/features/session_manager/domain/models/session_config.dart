import 'package:hoc_cung_tre_em/core/constants/app_constants.dart';

/// Cấu hình cho 1 buổi học — bố mẹ thiết lập trước khi bé bắt đầu
class SessionConfig {
  /// Thời gian mỗi phiên học (phút). Range: 15-30, default: 20
  final int studyDurationMinutes;

  /// Thời gian nghỉ giải lao (phút). Range: 3-10, default: 5
  final int breakDurationMinutes;

  /// Tổng số phiên trong buổi học. Range: 1-5, default: 3
  final int totalSessions;

  /// Số lần mất tập trung trước khi hệ thống tự pause. Default: 5
  final int maxDistractionsBeforePause;

  /// Môn học (hiển thị trên UI)
  final String subject;

  /// Bật camera theo dõi hành vi?
  final bool enableBehaviorMonitor;

  /// Dùng camera nào? true = SAU (default)
  final bool useBackCamera;

  const SessionConfig({
    this.studyDurationMinutes = AppConstants.defaultSessionMinutes,
    this.breakDurationMinutes = AppConstants.defaultBreakMinutes,
    this.totalSessions = 3,
    this.maxDistractionsBeforePause = 5,
    this.subject = 'Tự do',
    this.enableBehaviorMonitor = true,
    this.useBackCamera = true,
  });

  /// Tổng thời gian buổi học (tính cả nghỉ)
  int get totalDurationMinutes =>
      (studyDurationMinutes * totalSessions) +
      (breakDurationMinutes * (totalSessions - 1));

  /// Preset: Toán 20 phút
  factory SessionConfig.math() => const SessionConfig(
        subject: 'Toán',
        studyDurationMinutes: 20,
        totalSessions: 3,
      );

  /// Preset: Tiếng Việt 25 phút
  factory SessionConfig.vietnamese() => const SessionConfig(
        subject: 'Tiếng Việt',
        studyDurationMinutes: 25,
        totalSessions: 2,
      );

  /// Preset: Tự do 15 phút (nhẹ nhàng)
  factory SessionConfig.free() => const SessionConfig(
        subject: 'Ôn tập',
        studyDurationMinutes: 15,
        breakDurationMinutes: 5,
        totalSessions: 2,
      );

  SessionConfig copyWith({
    int? studyDurationMinutes,
    int? breakDurationMinutes,
    int? totalSessions,
    int? maxDistractionsBeforePause,
    String? subject,
    bool? enableBehaviorMonitor,
    bool? useBackCamera,
  }) {
    return SessionConfig(
      studyDurationMinutes: studyDurationMinutes ?? this.studyDurationMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      totalSessions: totalSessions ?? this.totalSessions,
      maxDistractionsBeforePause:
          maxDistractionsBeforePause ?? this.maxDistractionsBeforePause,
      subject: subject ?? this.subject,
      enableBehaviorMonitor:
          enableBehaviorMonitor ?? this.enableBehaviorMonitor,
      useBackCamera: useBackCamera ?? this.useBackCamera,
    );
  }
}
