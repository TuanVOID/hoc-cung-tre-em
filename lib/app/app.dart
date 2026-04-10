import 'package:flutter/material.dart';
import 'package:hoc_cung_tre_em/app/theme.dart';
import 'package:hoc_cung_tre_em/app/router.dart';

/// Root App Widget — Entry point của toàn bộ ứng dụng
class HocCungTreEmApp extends StatelessWidget {
  const HocCungTreEmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Học Cùng Trẻ Em',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
