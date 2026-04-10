import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoc_cung_tre_em/core/services/message_generator.dart';
import 'package:hoc_cung_tre_em/core/services/smart_tts_service.dart';
import 'package:hoc_cung_tre_em/features/behavior_monitor/domain/escalation_manager.dart';
import 'package:hoc_cung_tre_em/features/behavior_monitor/domain/models/behavior_models.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PROVIDER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final audioReminderProvider =
    NotifierProvider<AudioReminderNotifier, AudioReminderState>(
  AudioReminderNotifier.new,
);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STATE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AudioReminderState {
  /// Đang active? (true khi phiên học đang chạy)
  final bool isActive;

  /// Level hiện tại
  final ReminderLevel currentLevel;

  /// Tổng số lần nhắc
  final int totalReminders;

  /// Message vừa phát
  final String? lastMessage;

  /// TTS đang nói?
  final bool isSpeaking;

  const AudioReminderState({
    this.isActive = false,
    this.currentLevel = ReminderLevel.gentle,
    this.totalReminders = 0,
    this.lastMessage,
    this.isSpeaking = false,
  });

  AudioReminderState copyWith({
    bool? isActive,
    ReminderLevel? currentLevel,
    int? totalReminders,
    String? lastMessage,
    bool? isSpeaking,
  }) {
    return AudioReminderState(
      isActive: isActive ?? this.isActive,
      currentLevel: currentLevel ?? this.currentLevel,
      totalReminders: totalReminders ?? this.totalReminders,
      lastMessage: lastMessage ?? this.lastMessage,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NOTIFIER — Orchestrator kết nối tất cả
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// AudioReminderNotifier — Orchestrator kết nối:
///   Behavior Events → Escalation Manager → Message Generator → Smart TTS
class AudioReminderNotifier extends Notifier<AudioReminderState> {
  late final EscalationManager _escalation;
  late final SmartTtsService _tts;

  /// Stream subscription từ behavior monitor
  StreamSubscription<BehaviorEvent>? _behaviorSubscription;

  /// Callback khi force stop (gọi SessionManager.pause)
  void Function()? onForceStop;

  /// Callback khi thông báo bố mẹ
  void Function(String summary)? onParentAlert;

  @override
  AudioReminderState build() {
    _escalation = EscalationManager();
    _tts = SmartTtsService.instance;

    // Wire callbacks
    _escalation.onReminder = _onReminder;
    _escalation.onParentAlert = _onParentAlert;
    _escalation.onForceStop = _onForceStop;

    ref.onDispose(() {
      _behaviorSubscription?.cancel();
      _tts.stop();
    });

    return const AudioReminderState();
  }

  // ━━━━━━━━━━━━ PUBLIC ━━━━━━━━━━━━

  /// Bắt đầu lắng nghe behavior events
  Future<void> activate(Stream<BehaviorEvent> behaviorStream) async {
    await _tts.initialize();

    _behaviorSubscription?.cancel();
    _behaviorSubscription = behaviorStream.listen((event) {
      _escalation.handleBehaviorEvent(event);
    });

    state = state.copyWith(isActive: true);
    debugPrint('AudioReminder: Activated');
  }

  /// Dừng lắng nghe
  void deactivate() {
    _behaviorSubscription?.cancel();
    _behaviorSubscription = null;
    _tts.stop();
    state = state.copyWith(isActive: false);
    debugPrint('AudioReminder: Deactivated');
  }

  /// Reset (phiên mới)
  void reset() {
    _escalation.reset();
    state = const AudioReminderState(isActive: true);
  }

  /// Test: phát 1 câu nhắc nhở thử (cho Settings screen)
  Future<void> testReminder(ReminderLevel level) async {
    await _tts.initialize();
    final msg = MessageGenerator().getMessage(level: level);
    await _tts.speakWithLevel(msg, level);
    state = state.copyWith(lastMessage: msg, currentLevel: level);
  }

  // ━━━━━━━━━━━━ CALLBACKS ━━━━━━━━━━━━

  void _onReminder(String message, ReminderLevel level) {
    _tts.speakWithLevel(message, level);

    state = state.copyWith(
      currentLevel: level,
      totalReminders: state.totalReminders + 1,
      lastMessage: message,
      isSpeaking: true,
    );

    debugPrint('AudioReminder: [${level.name}] → "$message"');
  }

  void _onParentAlert(String summary) {
    onParentAlert?.call(summary);
    debugPrint('AudioReminder: 🔔 Parent alert → "$summary"');
    // TODO: Implement local notification (Phase 07)
  }

  void _onForceStop() {
    onForceStop?.call();
    debugPrint('AudioReminder: ⛔ Force stop triggered');
  }
}
