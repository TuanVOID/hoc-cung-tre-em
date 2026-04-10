import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoc_cung_tre_em/app/theme.dart';
import 'package:hoc_cung_tre_em/features/session_manager/domain/session_state_machine.dart';
import 'package:hoc_cung_tre_em/features/session_manager/domain/models/session_config.dart';
import 'package:hoc_cung_tre_em/features/session_manager/presentation/widgets/circular_timer.dart';
import 'package:hoc_cung_tre_em/features/session_manager/presentation/widgets/session_progress.dart';

/// SessionScreen — Màn hình phiên học chính
/// Hiển thị timer, trạng thái, nút điều khiển
class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStateProvider);

    return Scaffold(
      backgroundColor: _phaseColor(session.phase).withValues(alpha: 0.05),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: session.phase == SessionPhase.idle
              ? _buildSetupView(context, ref)
              : _buildActiveView(context, ref, session),
        ),
      ),
    );
  }

  // ━━━━━━ SETUP VIEW (Chọn preset trước khi học) ━━━━━━

  Widget _buildSetupView(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppTheme.spaceLg),

        // Header
        Text(
          'Chọn bài học hôm nay 📖',
          style: Theme.of(context).textTheme.displayLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spaceXs),
        Text(
          'Bấm vào một môn để bắt đầu nha con!',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppTheme.spaceLg),

        // Preset cards
        _buildPresetCard(
          context, ref,
          icon: Icons.calculate_outlined,
          title: 'Toán',
          subtitle: '20 phút × 3 phiên',
          config: SessionConfig.math(),
          color: const Color(0xFF0B57D0),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        _buildPresetCard(
          context, ref,
          icon: Icons.menu_book_outlined,
          title: 'Tiếng Việt',
          subtitle: '25 phút × 2 phiên',
          config: SessionConfig.vietnamese(),
          color: const Color(0xFF16A34A),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        _buildPresetCard(
          context, ref,
          icon: Icons.auto_stories_outlined,
          title: 'Ôn tập tự do',
          subtitle: '15 phút × 2 phiên',
          config: SessionConfig.free(),
          color: const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildPresetCard(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required SessionConfig config,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () {
          ref.read(sessionStateProvider.notifier).startSession(config);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceSm),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.labelLarge),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppTheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  // ━━━━━━ ACTIVE VIEW (Đang học) ━━━━━━

  Widget _buildActiveView(
      BuildContext context, WidgetRef ref, SessionState session) {
    final color = _phaseColor(session.phase);

    return Column(
      children: [
        // Header: Môn học + phiên
        _buildHeader(context, session, color),

        const Spacer(),

        // Circular Timer (trung tâm)
        CircularTimer(
          progress: session.timerProgress,
          remainingText: session.remainingFormatted,
          color: color,
          label: _phaseLabel(session.phase),
        ),

        const SizedBox(height: AppTheme.spaceMd),

        // Message
        if (session.message != null)
          Text(
            session.message!,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                ),
            textAlign: TextAlign.center,
          ),

        const Spacer(),

        // Session progress dots
        SessionProgressDots(
          currentSession: session.currentSession,
          totalSessions: session.config.totalSessions,
          phase: session.phase,
        ),

        const SizedBox(height: AppTheme.spaceMd),

        // Control buttons
        _buildControls(context, ref, session, color),

        const SizedBox(height: AppTheme.spaceSm),
      ],
    );
  }

  Widget _buildHeader(
      BuildContext context, SessionState session, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.config.subject,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Phiên ${session.currentSession}/${session.config.totalSessions}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        // Focus score badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Row(
            children: [
              Icon(Icons.visibility, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                '${session.focusScore.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(
      BuildContext context, WidgetRef ref, SessionState session, Color color) {
    final notifier = ref.read(sessionStateProvider.notifier);

    if (session.phase == SessionPhase.completed) {
      return ElevatedButton.icon(
        onPressed: () {
          // Reset về idle
          ref.invalidate(sessionStateProvider);
        },
        icon: const Icon(Icons.home_rounded),
        label: const Text('Về Trang Chủ'),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Dừng
        OutlinedButton(
          onPressed: () => notifier.stopSession(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.error,
            side: const BorderSide(color: AppTheme.error),
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: const Icon(Icons.stop_rounded, size: 24),
        ),

        const SizedBox(width: AppTheme.spaceMd),

        // Pause / Resume (nút lớn ở giữa)
        if (session.phase == SessionPhase.paused)
          ElevatedButton(
            onPressed: () => notifier.resume(),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(24),
            ),
            child: const Icon(Icons.play_arrow_rounded, size: 40),
          )
        else
          ElevatedButton(
            onPressed: () => notifier.pause(),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(24),
            ),
            child: const Icon(Icons.pause_rounded, size: 40),
          ),

        const SizedBox(width: AppTheme.spaceMd),

        // Skip (chuyển phase tiếp)
        OutlinedButton(
          onPressed: () {
            // Skip forward không implement ở phase này
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.onSurfaceVariant,
            side: const BorderSide(color: AppTheme.outline),
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: const Icon(Icons.skip_next_rounded, size: 24),
        ),
      ],
    );
  }

  // ━━━━━━ HELPERS ━━━━━━

  Color _phaseColor(SessionPhase phase) {
    return switch (phase) {
      SessionPhase.studying => AppTheme.primary,
      SessionPhase.onBreak => AppTheme.success,
      SessionPhase.paused => AppTheme.warning,
      SessionPhase.forceBreak => AppTheme.error,
      SessionPhase.completed => AppTheme.starGold,
      SessionPhase.idle => AppTheme.primary,
    };
  }

  String _phaseLabel(SessionPhase phase) {
    return switch (phase) {
      SessionPhase.studying => 'Đang học',
      SessionPhase.onBreak => 'Nghỉ giải lao',
      SessionPhase.paused => 'Tạm dừng',
      SessionPhase.forceBreak => 'Nghỉ bắt buộc',
      SessionPhase.completed => 'Hoàn thành!',
      SessionPhase.idle => '',
    };
  }
}
