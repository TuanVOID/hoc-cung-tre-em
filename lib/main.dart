import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hoc_cung_tre_em/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khóa xoay màn hình — chỉ cho portrait (dọc)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Status bar trong suốt cho giao diện Material sạch
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Khởi tạo Hive (local database)
  await Hive.initFlutter();

  // Chạy app với Riverpod ProviderScope
  runApp(
    const ProviderScope(
      child: HocCungTreEmApp(),
    ),
  );
}
