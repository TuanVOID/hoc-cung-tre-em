import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hoc_cung_tre_em/features/ai_tutor/domain/models/ocr_result.dart';
import 'package:hoc_cung_tre_em/features/ai_tutor/domain/subject_detector.dart';

/// OcrService — Nhận diện text tiếng Việt từ ảnh sách giáo khoa
/// Sử dụng Google ML Kit Text Recognition v2 (on-device)
class OcrService {
  late final TextRecognizer _textRecognizer;

  OcrService() {
    _textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin, // Tiếng Việt = Latin-based
    );
  }

  /// Xử lý ảnh từ file path → OcrResult
  Future<OcrResult> processImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await _textRecognizer.processImage(inputImage);

      final fullText = recognized.text;
      final blocks = _convertBlocks(recognized.blocks);
      final exercises = _parseExercises(fullText);
      final subject = SubjectDetector.detect(fullText);
      final confidence = _estimateConfidence(recognized.blocks);

      debugPrint('OCR: ${fullText.length} chars, ${exercises.length} exercises, subject=$subject');

      return OcrResult(
        fullText: fullText,
        blocks: blocks,
        exercises: exercises,
        detectedSubject: subject,
        confidence: confidence,
        processedAt: DateTime.now(),
        imagePath: imagePath,
      );
    } catch (e) {
      debugPrint('OCR Error: $e');
      return OcrResult.empty();
    }
  }

  /// Xử lý ảnh từ XFile (camera capture)
  Future<OcrResult> processXFile(XFile file) async {
    return processImage(file.path);
  }

  void dispose() {
    _textRecognizer.close();
  }

  // ━━━━━━━━━━━━ PRIVATE ━━━━━━━━━━━━

  List<OcrBlock> _convertBlocks(List<TextBlock> mlBlocks) {
    return mlBlocks.map((block) {
      return OcrBlock(
        text: block.text,
        boundingBox: Rect.fromLTRB(
          block.boundingBox.left,
          block.boundingBox.top,
          block.boundingBox.right,
          block.boundingBox.bottom,
        ),
        lines: block.lines.map((l) => l.text).toList(),
      );
    }).toList();
  }

  /// Parse bài tập từ text (detect "Bài 1:", "1.", "a)", v.v.)
  List<Exercise> _parseExercises(String text) {
    final exercises = <Exercise>[];

    // Pattern: "Bài 1:", "Bài 2.", "1.", "2)", "a)", "b."
    final pattern = RegExp(
      r'(?:Bài\s+)?(\d+|[a-dA-D])\s*[.):]\s*(.+?)(?=(?:Bài\s+)?(?:\d+|[a-dA-D])\s*[.):]\s*|$)',
      multiLine: true,
      dotAll: true,
    );

    for (final match in pattern.allMatches(text)) {
      final number = match.group(1) ?? '';
      final question = match.group(2)?.trim() ?? '';

      if (question.length > 5) {
        // Bỏ qua matches quá ngắn (noise)
        exercises.add(Exercise(
          number: number,
          question: _cleanQuestion(question),
        ));
      }
    }

    return exercises;
  }

  /// Dọn dẹp text câu hỏi
  String _cleanQuestion(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Ước tính confidence dựa trên quality của recognition
  double _estimateConfidence(List<TextBlock> blocks) {
    if (blocks.isEmpty) return 0.0;

    // Heuristic: nhiều text + ít block fragmentation = confidence cao
    final totalChars = blocks.fold<int>(0, (sum, b) => sum + b.text.length);
    if (totalChars < 10) return 0.3;
    if (totalChars < 50) return 0.6;
    return 0.85; // Printed Vietnamese text thường accurate
  }
}
