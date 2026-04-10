import 'package:flutter/material.dart';
import 'package:hoc_cung_tre_em/app/theme.dart';
import 'package:hoc_cung_tre_em/features/session_manager/domain/session_state_machine.dart';

/// SessionProgressDots — Hiển thị tiến độ phiên học: ● ● ○ (2/3)
class SessionProgressDots extends StatelessWidget {
  final int currentSession;
  final int totalSessions;
  final SessionPhase phase;

  const SessionProgressDots({
    super.key,
    required this.currentSession,
    required this.totalSessions,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSessions, (index) {
        final sessionNumber = index + 1;
        final isCompleted = sessionNumber < currentSession;
        final isCurrent = sessionNumber == currentSession;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isCurrent ? 32 : 12,
            height: 12,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.success
                  : isCurrent
                      ? _phaseColor(phase)
                      : AppTheme.outline,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }),
    );
  }

  Color _phaseColor(SessionPhase phase) {
    return switch (phase) {
      SessionPhase.studying => AppTheme.primary,
      SessionPhase.onBreak => AppTheme.success,
      SessionPhase.forceBreak => AppTheme.error,
      _ => AppTheme.primary,
    };
  }
}
