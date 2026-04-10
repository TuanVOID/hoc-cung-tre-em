import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoc_cung_tre_em/features/home/presentation/home_screen.dart';

/// App Router — Navigation configuration using GoRouter
/// Sử dụng declarative routing thay vì imperative Navigator.push
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // Trang chủ (Home)
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // Placeholder routes — sẽ thêm ở phases sau
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // GoRoute(path: '/study', name: 'study', ...),       // Phase 02-03
      // GoRoute(path: '/tutor', name: 'tutor', ...),       // Phase 05-06
      // GoRoute(path: '/dashboard', name: 'dashboard', ...), // Phase 07
      // GoRoute(path: '/settings', name: 'settings', ...), // Phase 07
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Trang không tìm thấy',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    ),
  );
}
