/// SubjectDetector — Phân loại môn học từ text OCR
/// Dùng keyword matching (simple classifier)
class SubjectDetector {
  SubjectDetector._();

  /// Detect môn học từ text sách giáo khoa
  static String detect(String text) {
    final lower = text.toLowerCase();

    // Đếm keywords match cho mỗi môn
    final scores = <String, int>{};

    for (final entry in _subjectKeywords.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (lower.contains(keyword.toLowerCase())) {
          score++;
        }
      }
      if (score > 0) {
        scores[entry.key] = score;
      }
    }

    if (scores.isEmpty) return 'Không xác định';

    // Trả về môn có score cao nhất
    return scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  // ━━━━━━━━━━━━ KEYWORD DATABASE ━━━━━━━━━━━━

  static const Map<String, List<String>> _subjectKeywords = {
    'Toán': [
      'tính', 'giải', 'bài toán', 'phép tính', 'cộng', 'trừ',
      'nhân', 'chia', 'số', 'đáp số', 'lời giải', 'phép cộng',
      'phép trừ', 'phép nhân', 'phép chia', 'hình học', 'tam giác',
      'hình vuông', 'hình tròn', 'chu vi', 'diện tích', 'đơn vị',
      'kilogram', 'mét', 'lít', 'cm', 'dm', 'km',
      '+', '-', '×', '÷', '=',
    ],

    'Tiếng Việt': [
      'tập đọc', 'chính tả', 'tập làm văn', 'luyện từ', 'câu',
      'kể chuyện', 'đọc hiểu', 'viết', 'từ ngữ', 'ngữ pháp',
      'đoạn văn', 'bài văn', 'dấu chấm', 'dấu phẩy', 'vần',
      'âm', 'thanh', 'tiếng', 'từ', 'câu hỏi', 'trả lời',
      'điền từ', 'nối', 'ghép',
    ],

    'Tự nhiên - Xã hội': [
      'tự nhiên', 'xã hội', 'quan sát', 'thí nghiệm', 'cơ thể',
      'động vật', 'thực vật', 'môi trường', 'gia đình', 'trường học',
      'sức khỏe', 'vệ sinh', 'an toàn', 'giao thông',
    ],

    'Tiếng Anh': [
      'listen', 'read', 'write', 'speak', 'hello', 'what',
      'where', 'how', 'english', 'the', 'is', 'are',
      'exercise', 'practice', 'complete', 'match',
    ],
  };
}
