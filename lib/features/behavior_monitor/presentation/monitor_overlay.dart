import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoc_cung_tre_em/app/theme.dart';
import 'package:hoc_cung_tre_em/features/behavior_monitor/domain/behavior_state.dart';
import 'package:hoc_cung_tre_em/features/behavior_monitor/domain/models/behavior_models.dart';
import 'package:hoc_cung_tre_em/core/services/camera_service.dart';

/// MonitorOverlay — Camera preview + trạng thái hành vi overlay
/// Chạy ở chế độ nhỏ gọn (mini) trên màn hình phiên học
class MonitorOverlay extends ConsumerWidget {
  /// Nếu true, hiện camera preview (cho bố mẹ debug).
  /// Default false: ẩn camera, chỉ hiện status icon.
  final bool showPreview;

  const MonitorOverlay({super.key, this.showPreview = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final behaviorState = ref.watch(behaviorStateProvider);

    if (!behaviorState.isMonitoring) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Camera preview (optional)
          if (showPreview) _buildCameraPreview(),

          // Status bar
          _buildStatusBar(context, behaviorState),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = CameraService.instance.controller;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        width: 120,
        height: 90,
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white54),
        ),
      );
    }

    return SizedBox(
      width: 120,
      height: 90,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusMd),
        ),
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context, BehaviorState state) {
    final (icon, color, label) = _behaviorDisplay(state.currentBehavior);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          // Focus score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              '${state.metrics.focusScore.toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Map hành vi → Icon + Màu + Label
  (IconData, Color, String) _behaviorDisplay(ChildBehavior behavior) {
    return switch (behavior) {
      ChildBehavior.focused => (
          Icons.check_circle,
          AppTheme.success,
          'Tập trung',
        ),
      ChildBehavior.distracted => (
          Icons.warning_amber_rounded,
          AppTheme.warning,
          'Mất tập trung',
        ),
      ChildBehavior.sleepy => (
          Icons.bedtime,
          const Color(0xFF7C3AED),
          'Buồn ngủ',
        ),
      ChildBehavior.absent => (
          Icons.person_off,
          AppTheme.error,
          'Rời chỗ',
        ),
      ChildBehavior.fidgeting => (
          Icons.directions_run,
          AppTheme.warning,
          'Nghịch',
        ),
    };
  }
}
