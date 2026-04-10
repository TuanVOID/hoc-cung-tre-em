import 'package:hoc_cung_tre_em/features/behavior_monitor/domain/models/behavior_models.dart';

/// Bản ghi lịch sử 1 phiên học — lưu vào Hive local DB
class SessionRecord {
  /// ID duy nhất
  final String id;

  /// Thời điểm bắt đầu
  final DateTime startTime;

  /// Thời điểm kết thúc
  final DateTime endTime;

  /// Tổng phút học
  final int totalStudyMinutes;

  /// Tổng phút nghỉ
  final int totalBreakMinutes;

  /// Điểm tập trung (0-100%) từ Behavior Monitor
  final double focusScore;

  /// Số lần mất tập trung
  final int distractionCount;

  /// Môn học
  final String subject;

  /// Hoàn thành bao nhiêu phiên / tổng phiên
  final int completedSessions;
  final int totalSessions;

  /// Lịch sử behavior events (serialize-friendly)
  final List<BehaviorEvent> events;

  const SessionRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.totalStudyMinutes = 0,
    this.totalBreakMinutes = 0,
    this.focusScore = 0,
    this.distractionCount = 0,
    this.subject = '',
    this.completedSessions = 0,
    this.totalSessions = 0,
    this.events = const [],
  });

  /// Tổng thời gian buổi học (phút)
  int get totalMinutes => endTime.difference(startTime).inMinutes;

  /// Đã hoàn thành tất cả phiên?
  bool get isCompleted => completedSessions >= totalSessions;
}
