import 'dart:math';
import 'package:hoc_cung_tre_em/features/behavior_monitor/domain/models/behavior_models.dart';

/// Mức độ escalation (leo thang nhắc nhở)
enum ReminderLevel {
  /// 🟢 Lần 1: Nhẹ nhàng
  gentle,

  /// 🟡 Lần 2-3: Nghiêm hơn
  firm,

  /// 🟠 Lần 4-5: Nghiêm túc
  serious,

  /// 🔴 Lần 6-7: Trách
  strict,

  /// ⛔ Lần 8+: Dừng + thông báo bố mẹ
  critical,
}

/// MessageGenerator — Hybrid Static + Dynamic messages
/// Static pool: 75+ messages (15 × 5 levels) — luôn available
/// Dynamic: AI generate khi LLM đã load (Phase 06) — bonus
class MessageGenerator {
  final _random = Random();

  /// Track 10 messages gần nhất để tránh lặp
  final List<String> _recentMessages = [];
  static const int _recentLimit = 10;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // PUBLIC API
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Lấy 1 câu nhắc nhở phù hợp — KHÔNG LẶP trong 10 lần gần nhất
  String getMessage({
    required ReminderLevel level,
    ChildBehavior? behavior,
    String? childName,
    int? minutesLeft,
  }) {
    // Ưu tiên 1: Behavior-specific message (nếu có)
    if (behavior != null && _behaviorMessages.containsKey(behavior)) {
      final msg = _pickNonRepeat(_behaviorMessages[behavior]!);
      if (msg != null) return _personalize(msg, childName, minutesLeft);
    }

    // Ưu tiên 2: Level-based message
    final levelMessages = _staticMessages[level] ?? _staticMessages[ReminderLevel.gentle]!;
    final msg = _pickNonRepeat(levelMessages) ?? levelMessages[_random.nextInt(levelMessages.length)];

    return _personalize(msg, childName, minutesLeft);
  }

  /// Reset (gọi khi bắt đầu phiên mới)
  void reset() {
    _recentMessages.clear();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ANTI-REPETITION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  String? _pickNonRepeat(List<String> pool) {
    // Lọc ra messages chưa dùng gần đây
    final available = pool.where((m) => !_recentMessages.contains(m)).toList();
    if (available.isEmpty) return null;

    final chosen = available[_random.nextInt(available.length)];
    _recentMessages.add(chosen);
    if (_recentMessages.length > _recentLimit) {
      _recentMessages.removeAt(0);
    }
    return chosen;
  }

  /// Cá nhân hóa message (thay {name}, {minutes})
  String _personalize(String msg, String? childName, int? minutesLeft) {
    var result = msg;
    if (childName != null) {
      result = result.replaceAll('Con', childName);
    }
    if (minutesLeft != null && result.contains('{minutes}')) {
      result = result.replaceAll('{minutes}', '$minutesLeft');
    }
    return result;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📝 STATIC MESSAGE POOL — 75+ messages
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static const Map<ReminderLevel, List<String>> _staticMessages = {
    // ━━━ GENTLE (🟢) — 15 messages ━━━
    ReminderLevel.gentle: [
      'Con ơi, tập trung vào bài nhé!',
      'Nhìn vào sách nào con!',
      'Con xem bài tập đi nào!',
      'Này con, quay lại bài học nào!',
      'Con tập trung chút nha, bài này dễ lắm!',
      'Ơ con, đang học bài mà, tập trung nào!',
      'Con xem lại bài đi, sắp xong rồi!',
      'Nào nào, mình cùng làm bài tiếp nhé!',
      'Con ơi, bài này thú vị lắm, đọc thử đi!',
      'Tập trung nào con, mẹ tin con làm được!',
      'Con nhìn vào đây nè, bài tập đang chờ con!',
      'Ê con, đừng lo ra nha, mình học tiếp đi!',
      'Con ơi, đọc đề bài lần nữa đi nào!',
      'Nào con, sách đang mở trang này nè!',
      'Con tập trung chút xíu nữa thôi, được không?',
    ],

    // ━━━ FIRM (🟡) — 15 messages ━━━
    ReminderLevel.firm: [
      'Con cần quay lại bài học đi!',
      'Con đang mất tập trung đấy!',
      'Tập trung lại nào, con làm được mà!',
      'Con phải chú ý hơn, bài này quan trọng đấy!',
      'Đây là lần thứ hai rồi, con tập trung đi!',
      'Con đang xao nhãng, quay lại bài ngay nào!',
      'Không được nhìn chỗ khác, học bài đi con!',
      'Con muốn nghỉ sớm hay tập trung học xong?',
      'Mẹ thấy con không tập trung, cố lên nhé!',
      'Con ơi, nếu tập trung thì sẽ xong nhanh hơn!',
      'Bài này không khó đâu, con nhìn lại đi!',
      'Con cần nghiêm túc hơn một chút nha!',
      'Tập trung đi con, rồi được nghỉ chơi!',
      'Con mà làm xong bài này thì giỏi lắm đấy!',
      'Thôi nào, quay lại học đi, đừng để mẹ nhắc nữa!',
    ],

    // ━━━ SERIOUS (🟠) — 15 messages ━━━
    ReminderLevel.serious: [
      'Con vi phạm nhiều lần rồi đấy, cố gắng lên!',
      'Nếu con không tập trung thì sẽ phải nghỉ sớm!',
      'Con cần nghiêm túc hơn với bài học!',
      'Đã nhắc con nhiều lần rồi, tập trung đi!',
      'Con không chịu học thì sẽ không hiểu bài đâu!',
      'Mẹ rất thất vọng khi con không chịu tập trung!',
      'Con cần ngồi yên và làm bài ngay bây giờ!',
      'Nếu tiếp tục thế này, mẹ sẽ phải can thiệp đấy!',
      'Con đã bị nhắc nhiều lần, lần này phải tập trung!',
      'Bạn bè con đang chăm chỉ học, con cũng phải cố!',
      'Thời gian nghỉ sẽ bị rút ngắn nếu con không học!',
      'Con muốn bố mẹ biết con không chịu học không?',
      'Đây là cơ hội cuối để con tự giác, tập trung nào!',
      'Con đang lãng phí thời gian, hãy tập trung lại!',
      'Mẹ mong con nghiêm túc, chỉ còn một chút nữa thôi!',
    ],

    // ━━━ STRICT (🔴) — 15 messages ━━━
    ReminderLevel.strict: [
      'Con không tập trung sẽ không hiểu bài đâu!',
      'Bố mẹ sẽ biết con không chịu học đấy!',
      'Cố gắng tập trung, chỉ còn ít phút nữa thôi!',
      'Mẹ rất buồn khi con cứ không chịu học!',
      'Con làm mẹ rất lo lắng khi không tập trung!',
      'Nếu tiếp tục, phiên học sẽ bị dừng ngay!',
      'Con đã được nhắc quá nhiều lần rồi!',
      'Bố mẹ đang rất thất vọng về thái độ học của con!',
      'Con cần hiểu rằng học tập là trách nhiệm của con!',
      'Đây là lần nhắc cuối trước khi phải tạm dừng!',
      'Con không muốn học thì sẽ phải nghỉ rồi giải thích với bố mẹ!',
      'Mẹ sẽ phải nói chuyện với con sau buổi học!',
      'Con hãy tự hỏi mình: con muốn giỏi hay muốn bị la?',
      'Lần nữa không tập trung, mẹ sẽ dừng buổi học!',
      'Con cần phải thay đổi thái độ ngay lập tức!',
    ],

    // ━━━ CRITICAL (⛔) — 5 messages ━━━
    ReminderLevel.critical: [
      'Con vi phạm quá nhiều, phải tạm dừng để nghỉ rồi!',
      'Bố mẹ đã được thông báo. Con nghỉ ngơi rồi học lại nhé.',
      'Buổi học tạm dừng. Con hãy bình tĩnh lại.',
      'Mẹ rất buồn nhưng phải dừng buổi học. Con nghỉ đi.',
      'Con không hợp tác, buổi học phải tạm ngưng.',
    ],
  };

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎯 BEHAVIOR-SPECIFIC MESSAGES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static const Map<ChildBehavior, List<String>> _behaviorMessages = {
    ChildBehavior.distracted: [
      'Con đang nhìn đi chỗ khác, quay lại bài nhé!',
      'Ơ, con nhìn gì thế? Quay lại bài học nào!',
      'Con đang mơ màng à? Tập trung nào!',
      'Mắt con đang nhìn đâu thế? Vào bài đi!',
      'Con ơi, bài tập ở đây cơ mà, nhìn lại đi!',
    ],

    ChildBehavior.sleepy: [
      'Con buồn ngủ rồi à? Nghỉ chút đi rồi học tiếp!',
      'Mắt con díp lại rồi kìa! Rửa mặt đi con!',
      'Con mệt rồi phải không? Nghỉ giải lao nhé!',
      'Ôi, con ngủ gật à? Đứng dậy vận động chút!',
      'Con buồn ngủ thì uống nước, rồi học tiếp nha!',
    ],

    ChildBehavior.absent: [
      'Con đi đâu rồi? Quay lại chỗ ngồi nào!',
      'Ơ, con biến mất rồi! Quay lại học nào!',
      'Con ơi, mẹ không thấy con, quay lại đi!',
      'Con chạy đi đâu thế? Về bàn học ngay!',
      'Này, con bỏ chỗ ngồi rồi kìa! Quay lại!',
    ],

    ChildBehavior.fidgeting: [
      'Con ngồi yên học bài đi nào!',
      'Con nghịch gì thế? Tập trung vào bài!',
      'Ngồi yên nào con, đừng nhúc nhích nữa!',
      'Con ngọ nguậy hoài, ngồi ngay ngắn lại đi!',
      'Con ơi, ngồi nghiêm chỉnh rồi học tiếp nào!',
    ],
  };
}
