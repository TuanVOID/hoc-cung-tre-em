import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoc_cung_tre_em/app/theme.dart';

/// HomeScreen — Trang chủ chính của App
/// Đây là nơi bé chọn "Vào học" hoặc "Hỏi gia sư"
/// Bố mẹ có thể bấm vào Settings (icon góc phải)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Column(
            children: [
              // ━━━━ HEADER ━━━━
              _buildHeader(context),

              const SizedBox(height: AppTheme.spaceLg),

              // ━━━━ WELCOME SECTION ━━━━
              _buildWelcomeSection(context),

              const Spacer(),

              // ━━━━ ACTION BUTTONS ━━━━
              _buildActionButtons(context),

              const SizedBox(height: AppTheme.spaceLg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Avatar + Tên bé
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryContainer,
              child: const Icon(
                Icons.face,
                size: 28,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: AppTheme.spaceXs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào! 👋',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  'Bé Nhím',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ],
        ),

        // Ngôi sao + Settings
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppTheme.starGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppTheme.starGold,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '12',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceXs),
            IconButton(
              onPressed: () {
                // TODO: Navigate to parent settings (Phase 07)
              },
              icon: const Icon(Icons.settings_outlined),
              color: AppTheme.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          children: [
            // Mascot placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 64,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              'Hôm nay mình học gì nhỉ? 📚',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              'Chọn một hoạt động bên dưới để bắt đầu nào!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Nút "Vào Học" — Primary action
        ElevatedButton.icon(
          onPressed: () => context.push('/study'),
          icon: const Icon(Icons.play_arrow_rounded, size: 28),
          label: const Text('Vào Học'),
        ),

        const SizedBox(height: AppTheme.spaceSm),

        // Nút "Hỏi Gia Sư" — Secondary action
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Navigate to AI tutor camera (Phase 05-06)
          },
          icon: const Icon(Icons.camera_alt_outlined, size: 24),
          label: const Text('Hỏi Gia Sư'),
        ),
      ],
    );
  }
}
