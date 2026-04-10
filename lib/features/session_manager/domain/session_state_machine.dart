import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoc_cung_tre_em/features/session_manager/domain/models/session_config.dart';
import 'package:hoc_cung_tre_em/features/session_manager/domain/models/session_record.dart';
import 'package:hoc_cung_tre_em/features/behavior_monitor/domain/models/behavior_models.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ENUMS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Các trạng thái của State Machine
/// IDLE → STUDYING → BREAK → STUDYING → ... → COMPLETED
enum SessionPhase {
  /// Chưa bắt đầu
  idle,

  /// Đang học — camera ON
  studying,

  /// Nghỉ giải lao — camera OFF
  onBreak,

  /// Tạm dừng (user bấm pause hoặc system auto-pause)
  paused,

  /// Nghỉ bắt buộc do vi phạm quá nhiều
  forceBreak,

  /// Hoàn thành toàn bộ buổi học
  completed,
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STATE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class SessionState {
  final SessionPhase phase;
  final SessionConfig config;

  /// Phiên hiện tại (1-indexed)
  final int currentSession;

  /// Giây còn lại của phase hiện tại (study hoặc break)
  final int remainingSeconds;

  /// Tổng giây đã học (tích lũy qua tất cả phiên)
  final int totalStudySeconds;

  /// Tổng giây nghỉ
  final int totalBreakSeconds;

  /// Số lần mất tập trung trong phiên hiện tại
  final int currentDistractions;

  /// Focus score (từ behavior monitor)
  final double focusScore;

  /// Phase trước khi pause (để resume đúng chỗ)
  final SessionPhase? pausedFromPhase;

  /// Thời điểm bắt đầu buổi học
  final DateTime? startedAt;

  /// Thông báo hiện tại (hiển thị cho trẻ)
  final String? message;

  const SessionState({
    this.phase = SessionPhase.idle,
    this.config = const SessionConfig(),
    this.currentSession = 1,
    this.remainingSeconds = 0,
    this.totalStudySeconds = 0,
    this.totalBreakSeconds = 0,
    this.currentDistractions = 0,
    this.focusScore = 100.0,
    this.pausedFromPhase,
    this.startedAt,
    this.message,
  });

  /// % tiến độ của timer hiện tại (0.0 - 1.0)
  double get timerProgress {
    final totalSec = phase == SessionPhase.studying
        ? config.studyDurationMinutes * 60
        : config.breakDurationMinutes * 60;
    if (totalSec == 0) return 0;
    return 1.0 - (remainingSeconds / totalSec);
  }

  /// Hiển thị thời gian còn lại dạng "MM:SS"
  String get remainingFormatted {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Tổng phút đã học
  int get totalStudyMinutes => totalStudySeconds ~/ 60;

  SessionState copyWith({
    SessionPhase? phase,
    SessionConfig? config,
    int? currentSession,
    int? remainingSeconds,
    int? totalStudySeconds,
    int? totalBreakSeconds,
    int? currentDistractions,
    double? focusScore,
    SessionPhase? pausedFromPhase,
    DateTime? startedAt,
    String? message,
  }) {
    return SessionState(
      phase: phase ?? this.phase,
      config: config ?? this.config,
      currentSession: currentSession ?? this.currentSession,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalStudySeconds: totalStudySeconds ?? this.totalStudySeconds,
      totalBreakSeconds: totalBreakSeconds ?? this.totalBreakSeconds,
      currentDistractions: currentDistractions ?? this.currentDistractions,
      focusScore: focusScore ?? this.focusScore,
      pausedFromPhase: pausedFromPhase ?? this.pausedFromPhase,
      startedAt: startedAt ?? this.startedAt,
      message: message,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PROVIDER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final sessionStateProvider =
    NotifierProvider<SessionStateNotifier, SessionState>(
  SessionStateNotifier.new,
);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NOTIFIER (STATE MACHINE)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class SessionStateNotifier extends Notifier<SessionState> {
  Timer? _timer;

  /// Callback khi session hoàn thành (để lưu lịch sử)
  void Function(SessionRecord record)? onSessionCompleted;

  @override
  SessionState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const SessionState();
  }

  // ━━━━━━ PUBLIC API ━━━━━━

  /// Bắt đầu buổi học mới với config
  void startSession(SessionConfig config) {
    _timer?.cancel();

    state = SessionState(
      phase: SessionPhase.studying,
      config: config,
      currentSession: 1,
      remainingSeconds: config.studyDurationMinutes * 60,
      startedAt: DateTime.now(),
      message: 'Bắt đầu học ${config.subject} nào! 📚',
    );

    _startTimer();
    debugPrint('Session: Started — ${config.subject}, ${config.studyDurationMinutes}min x ${config.totalSessions} sessions');
  }

  /// Pause (user bấm hoặc system auto-pause)
  void pause({String? reason}) {
    if (state.phase != SessionPhase.studying &&
        state.phase != SessionPhase.onBreak) {
      return;
    }

    _timer?.cancel();
    state = state.copyWith(
      phase: SessionPhase.paused,
      pausedFromPhase: state.phase,
      message: reason ?? 'Tạm dừng ⏸️',
    );
    debugPrint('Session: Paused (from ${state.pausedFromPhase?.name})');
  }

  /// Resume từ pause
  void resume() {
    if (state.phase != SessionPhase.paused) return;

    final resumePhase = state.pausedFromPhase ?? SessionPhase.studying;
    state = state.copyWith(
      phase: resumePhase,
      message: resumePhase == SessionPhase.studying
          ? 'Tiếp tục học nào! 💪'
          : 'Đang nghỉ giải lao 🧃',
    );

    _startTimer();
    debugPrint('Session: Resumed → ${resumePhase.name}');
  }

  /// Dừng buổi học hoàn toàn
  void stopSession() {
    _timer?.cancel();
    _emitRecord();

    state = state.copyWith(
      phase: SessionPhase.completed,
      message: 'Buổi học kết thúc! Giỏi lắm! 🌟',
    );
    debugPrint('Session: Stopped');
  }

  /// Nhận behavior event từ Behavior Monitor
  void onBehaviorEvent(BehaviorEvent event) {
    if (state.phase != SessionPhase.studying) return;

    if (event.behavior != ChildBehavior.focused) {
      final newCount = state.currentDistractions + 1;
      state = state.copyWith(currentDistractions: newCount);

      // Auto force-break nếu vượt ngưỡng
      if (newCount >= state.config.maxDistractionsBeforePause) {
        _forceBreak();
      }
    }
  }

  /// Cập nhật focus score (gọi từ behavior monitor)
  void updateFocusScore(double score) {
    state = state.copyWith(focusScore: score);
  }

  // ━━━━━━ PRIVATE ━━━━━━

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final remaining = state.remainingSeconds - 1;

    if (remaining <= 0) {
      _onTimerComplete();
      return;
    }

    // Cập nhật tổng thời gian
    if (state.phase == SessionPhase.studying) {
      state = state.copyWith(
        remainingSeconds: remaining,
        totalStudySeconds: state.totalStudySeconds + 1,
      );
    } else if (state.phase == SessionPhase.onBreak ||
        state.phase == SessionPhase.forceBreak) {
      state = state.copyWith(
        remainingSeconds: remaining,
        totalBreakSeconds: state.totalBreakSeconds + 1,
      );
    }

    // Thông báo "còn 5 phút"
    if (remaining == 300 && state.phase == SessionPhase.studying) {
      state = state.copyWith(message: 'Còn 5 phút nữa! Cố lên! 💪');
    }
    // Thông báo "còn 1 phút"
    if (remaining == 60 && state.phase == SessionPhase.studying) {
      state = state.copyWith(message: 'Sắp xong rồi! Còn 1 phút! ⏰');
    }
  }

  void _onTimerComplete() {
    _timer?.cancel();

    switch (state.phase) {
      case SessionPhase.studying:
        // Hết giờ học → check có phiên tiếp không
        if (state.currentSession >= state.config.totalSessions) {
          // Hết buổi!
          _emitRecord();
          state = state.copyWith(
            phase: SessionPhase.completed,
            remainingSeconds: 0,
            message: 'Hoàn thành buổi học! Giỏi lắm! 🎉🌟',
          );
          debugPrint('Session: COMPLETED all sessions');
        } else {
          // Chuyển sang break
          state = state.copyWith(
            phase: SessionPhase.onBreak,
            remainingSeconds: state.config.breakDurationMinutes * 60,
            message: 'Giờ nghỉ! Uống nước, vận động nhé! 🧃🏃',
          );
          _startTimer();
          debugPrint('Session: Study done → Break');
        }

      case SessionPhase.onBreak:
      case SessionPhase.forceBreak:
        // Hết giờ nghỉ → phiên học tiếp theo
        state = state.copyWith(
          phase: SessionPhase.studying,
          currentSession: state.currentSession + 1,
          remainingSeconds: state.config.studyDurationMinutes * 60,
          currentDistractions: 0, // Reset distraction counter
          message: 'Quay lại học nào! Phiên ${state.currentSession + 1}/${state.config.totalSessions} 📖',
        );
        _startTimer();
        debugPrint('Session: Break done → Study (session ${state.currentSession})');

      default:
        break;
    }
  }

  /// Force break: trẻ vi phạm quá nhiều
  void _forceBreak() {
    _timer?.cancel();
    state = state.copyWith(
      phase: SessionPhase.forceBreak,
      remainingSeconds: state.config.breakDurationMinutes * 60,
      message: 'Nghỉ một chút đã nhé! Con cần tập trung hơn 😊',
    );
    _startTimer();
    debugPrint('Session: Force break (distractions: ${state.currentDistractions})');
  }

  void _emitRecord() {
    final record = SessionRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: state.startedAt ?? DateTime.now(),
      endTime: DateTime.now(),
      totalStudyMinutes: state.totalStudyMinutes,
      totalBreakMinutes: state.totalBreakSeconds ~/ 60,
      focusScore: state.focusScore,
      distractionCount: state.currentDistractions,
      subject: state.config.subject,
      completedSessions: state.currentSession,
      totalSessions: state.config.totalSessions,
    );
    onSessionCompleted?.call(record);
  }
}
