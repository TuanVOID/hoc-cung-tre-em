import 'package:flutter/foundation.dart';
import 'package:hoc_cung_tre_em/core/services/message_generator.dart';
import 'package:hoc_cung_tre_em/features/behavior_monitor/domain/models/behavior_models.dart';

/// EscalationManager — Quản lý mức độ leo thang nhắc nhở
///
/// Logic escalation:
///   distractionCount: 1     → gentle   (🟢)
///   distractionCount: 2-3   → firm     (🟡)
///   distractionCount: 4-5   → serious  (🟠)
///   distractionCount: 6-7   → strict   (🔴)
///   distractionCount: 8+    → critical (⛔) → PAUSE session
///
/// Cooldown: 10 giây giữa 2 lần nhắc (tránh spam audio)
class EscalationManager {
  final MessageGenerator _messageGenerator = MessageGenerator();

  /// Số lần vi phạm trong phiên hiện tại
  int _distractionCount = 0;

  /// Thời điểm nhắc nhở lần cuối
  DateTime? _lastReminderTime;

  /// Cooldown giữa 2 lần nhắc (giây)
  static const int _cooldownSeconds = 10;

  /// Callback khi cần phát nhắc nhở
  void Function(String message, ReminderLevel level)? onReminder;

  /// Callback khi cần thông báo bố mẹ (critical level)
  void Function(String summary)? onParentAlert;

  /// Callback khi cần force pause session
  void Function()? onForceStop;

  // ━━━━━━━━━━━━ PUBLIC ━━━━━━━━━━━━

  int get distractionCount => _distractionCount;
  ReminderLevel get currentLevel => _getLevel(_distractionCount);

  /// Xử lý behavior event = quyết định có nhắc hay không
  void handleBehaviorEvent(BehaviorEvent event) {
    // Chỉ nhắc khi hành vi xấu
    if (event.behavior == ChildBehavior.focused) return;

    _distractionCount++;
    final level = _getLevel(_distractionCount);

    // Kiểm tra cooldown
    if (!_isCooldownPassed()) {
      debugPrint('Escalation: Cooldown active, skipping reminder #$_distractionCount');
      return;
    }

    _lastReminderTime = DateTime.now();

    // Lấy message phù hợp
    final message = _messageGenerator.getMessage(
      level: level,
      behavior: event.behavior,
    );

    debugPrint('Escalation: Level ${level.name} (#$_distractionCount) → "$message"');

    // Gọi callback nhắc nhở
    onReminder?.call(message, level);

    // Critical level → thông báo bố mẹ + force stop
    if (level == ReminderLevel.critical) {
      onParentAlert?.call(
        'Con đã mất tập trung $_distractionCount lần trong phiên học.',
      );
      onForceStop?.call();
    }
  }

  /// Reset (phiên mới hoặc sau break)
  void reset() {
    _distractionCount = 0;
    _lastReminderTime = null;
    _messageGenerator.reset();
    debugPrint('Escalation: Reset');
  }

  // ━━━━━━━━━━━━ PRIVATE ━━━━━━━━━━━━

  bool _isCooldownPassed() {
    if (_lastReminderTime == null) return true;
    final elapsed = DateTime.now().difference(_lastReminderTime!).inSeconds;
    return elapsed >= _cooldownSeconds;
  }

  ReminderLevel _getLevel(int count) {
    if (count <= 1) return ReminderLevel.gentle;
    if (count <= 3) return ReminderLevel.firm;
    if (count <= 5) return ReminderLevel.serious;
    if (count <= 7) return ReminderLevel.strict;
    return ReminderLevel.critical;
  }
}
