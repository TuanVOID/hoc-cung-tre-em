import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hoc_cung_tre_em/app/theme.dart';
import 'package:hoc_cung_tre_em/features/ai_tutor/domain/models/ocr_result.dart';

/// OcrPreview — Hiển thị kết quả OCR để user xác nhận trước khi hỏi AI
class OcrPreview extends StatelessWidget {
  final OcrResult result;
  final String? imagePath;
  final VoidCallback onRetake;
  final void Function(String text) onAskTutor;

  const OcrPreview({
    super.key,
    required this.result,
    this.imagePath,
    required this.onRetake,
    required this.onAskTutor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          // Top bar
          _buildTopBar(context),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ảnh thu nhỏ
                  if (imagePath != null) _buildThumbnail(),

                  const SizedBox(height: AppTheme.spaceSm),

                  // Info badges
                  _buildInfoBadges(context),

                  const SizedBox(height: AppTheme.spaceSm),

                  // OCR Text
                  _buildTextCard(context),

                  const SizedBox(height: AppTheme.spaceSm),

                  // Exercises (nếu có)
                  if (result.hasExercises) _buildExerciseList(context),
                ],
              ),
            ),
          ),

          // Bottom buttons
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSm,
        vertical: AppTheme.spaceXs,
      ),
      color: AppTheme.surface,
      child: Row(
        children: [
          IconButton(
            onPressed: onRetake,
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              'Kết quả nhận diện',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // balance
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Image.file(
        File(imagePath!),
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildInfoBadges(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        // Subject badge
        _badge(
          icon: Icons.book_outlined,
          label: result.detectedSubject,
          color: AppTheme.primary,
        ),
        // Confidence badge
        _badge(
          icon: Icons.verified_outlined,
          label: '${(result.confidence * 100).toStringAsFixed(0)}% chính xác',
          color: result.confidence > 0.7 ? AppTheme.success : AppTheme.warning,
        ),
        // Exercise count
        if (result.hasExercises)
          _badge(
            icon: Icons.assignment_outlined,
            label: '${result.exercises.length} bài tập',
            color: AppTheme.secondary,
          ),
      ],
    );
  }

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_fields, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Nội dung nhận diện',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                      ),
                ),
              ],
            ),
            const Divider(),
            SelectableText(
              result.hasText
                  ? result.fullText
                  : 'Không nhận diện được text. Thử chụp lại rõ hơn nhé!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, size: 20, color: AppTheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Bài tập phát hiện',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                      ),
                ),
              ],
            ),
            const Divider(),
            ...result.exercises.map((ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Số bài tập
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            ex.number,
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ex.question,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      // Nút hỏi bài này
                      IconButton(
                        onPressed: () => onAskTutor(ex.question),
                        icon: const Icon(
                          Icons.smart_toy_outlined,
                          color: AppTheme.primary,
                          size: 22,
                        ),
                        tooltip: 'Hỏi gia sư bài này',
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceSm),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Chụp lại
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRetake,
              icon: const Icon(Icons.camera_alt_outlined, size: 20),
              label: const Text('Chụp lại'),
            ),
          ),
          const SizedBox(width: AppTheme.spaceSm),
          // Hỏi gia sư toàn bộ
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: result.hasText
                  ? () => onAskTutor(result.fullText)
                  : null,
              icon: const Icon(Icons.smart_toy_rounded, size: 22),
              label: const Text('Hỏi Gia Sư'),
            ),
          ),
        ],
      ),
    );
  }
}
