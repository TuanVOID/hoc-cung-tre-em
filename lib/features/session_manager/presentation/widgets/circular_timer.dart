import 'dart:math';
import 'package:flutter/material.dart';

/// CircularTimer — Widget timer hình tròn animated
/// Hiển thị progress ring + thời gian còn lại ở giữa
class CircularTimer extends StatelessWidget {
  /// Tiến độ (0.0 → 1.0)
  final double progress;

  /// Text thời gian còn lại (ví dụ: "18:32")
  final String remainingText;

  /// Màu chính (thay đổi theo phase: xanh = học, cam = nghỉ)
  final Color color;

  /// Label phụ (ví dụ: "Đang học", "Nghỉ giải lao")
  final String label;

  const CircularTimer({
    super.key,
    required this.progress,
    required this.remainingText,
    required this.color,
    this.label = '',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 10,
              color: color.withValues(alpha: 0.15),
              strokeCap: StrokeCap.round,
            ),
          ),

          // Progress ring (animated)
          SizedBox(
            width: 220,
            height: 220,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return CustomPaint(
                  painter: _RingPainter(
                    progress: value,
                    color: color,
                    strokeWidth: 10,
                  ),
                );
              },
            ),
          ),

          // Center text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                remainingText,
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 2,
                ),
              ),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter cho progress ring
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Vẽ arc từ trên xuống theo chiều kim đồng hồ
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // bắt đầu từ 12 giờ
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
