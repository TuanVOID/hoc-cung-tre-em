import 'dart:ui';

/// Kết quả OCR từ ảnh sách giáo khoa
class OcrResult {
  /// Toàn bộ text nhận diện được
  final String fullText;

  /// Danh sách block text (từ ML Kit)
  final List<OcrBlock> blocks;

  /// Danh sách bài tập đã parse (1., 2., a), b)...)
  final List<Exercise> exercises;

  /// Môn học detected (Toán, Tiếng Việt, TNXH, Tiếng Anh)
  final String detectedSubject;

  /// Độ tin cậy OCR (0.0 → 1.0)
  final double confidence;

  /// Thời điểm xử lý
  final DateTime processedAt;

  /// Đường dẫn ảnh gốc (local)
  final String? imagePath;

  const OcrResult({
    required this.fullText,
    this.blocks = const [],
    this.exercises = const [],
    this.detectedSubject = 'Không xác định',
    this.confidence = 0.0,
    required this.processedAt,
    this.imagePath,
  });

  /// Có tìm thấy bài tập không?
  bool get hasExercises => exercises.isNotEmpty;

  /// Có text không?
  bool get hasText => fullText.trim().isNotEmpty;

  factory OcrResult.empty() => OcrResult(
        fullText: '',
        processedAt: DateTime.now(),
      );
}

/// 1 block text (đoạn văn, tiêu đề, v.v.)
class OcrBlock {
  final String text;
  final Rect boundingBox;
  final List<String> lines;

  const OcrBlock({
    required this.text,
    required this.boundingBox,
    this.lines = const [],
  });
}

/// 1 bài tập được parse từ OCR text
class Exercise {
  /// Số thứ tự bài (1, 2, 3... hoặc a, b, c...)
  final String number;

  /// Nội dung câu hỏi
  final String question;

  /// Ngữ cảnh/đề bài kèm theo (nếu có)
  final String? context;

  /// Vị trí trên ảnh gốc
  final Rect? boundingBox;

  const Exercise({
    required this.number,
    required this.question,
    this.context,
    this.boundingBox,
  });

  @override
  String toString() => 'Bài $number: $question';
}
