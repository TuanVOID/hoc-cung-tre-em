import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoc_cung_tre_em/core/services/camera_service.dart';
import 'package:hoc_cung_tre_em/features/behavior_monitor/data/face_analyzer.dart';
import 'package:hoc_cung_tre_em/features/behavior_monitor/domain/behavior_classifier.dart';
import 'package:hoc_cung_tre_em/features/behavior_monitor/domain/models/behavior_models.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// RIVERPOD PROVIDERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Provider cho trạng thái hành vi hiện tại
final behaviorStateProvider =
    NotifierProvider<BehaviorStateNotifier, BehaviorState>(
  BehaviorStateNotifier.new,
);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STATE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Trạng thái tổng hợp của Behavior Monitor
class BehaviorState {
  /// Hành vi hiện tại của trẻ
  final ChildBehavior currentBehavior;

  /// Metrics tổng hợp phiên học
  final BehaviorMetrics metrics;

  /// Face analysis frame gần nhất (cho UI debug overlay)
  final FaceAnalysis? lastFaceAnalysis;

  /// Monitoring đang chạy?
  final bool isMonitoring;

  /// Camera đang dùng back hay front?
  final bool isBackCamera;

  /// Có lỗi gì không?
  final String? error;

  const BehaviorState({
    this.currentBehavior = ChildBehavior.focused,
    this.metrics = const BehaviorMetrics(),
    this.lastFaceAnalysis,
    this.isMonitoring = false,
    this.isBackCamera = true,
    this.error,
  });

  BehaviorState copyWith({
    ChildBehavior? currentBehavior,
    BehaviorMetrics? metrics,
    FaceAnalysis? lastFaceAnalysis,
    bool? isMonitoring,
    bool? isBackCamera,
    String? error,
  }) {
    return BehaviorState(
      currentBehavior: currentBehavior ?? this.currentBehavior,
      metrics: metrics ?? this.metrics,
      lastFaceAnalysis: lastFaceAnalysis ?? this.lastFaceAnalysis,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      isBackCamera: isBackCamera ?? this.isBackCamera,
      error: error,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NOTIFIER (Riverpod 3.x)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Quản lý vòng đời monitoring: Start → Frame analysis → Behavior event → Stop
class BehaviorStateNotifier extends Notifier<BehaviorState> {
  final _cameraService = CameraService.instance;
  late final FaceAnalyzer _faceAnalyzer;
  late final BehaviorClassifier _classifier;

  /// Stream controller để các module khác subscribe (ví dụ: Audio Reminder)
  final _behaviorEventController = StreamController<BehaviorEvent>.broadcast();
  Stream<BehaviorEvent> get behaviorEvents => _behaviorEventController.stream;

  Timer? _metricsTimer;
  DateTime? _sessionStartTime;

  @override
  BehaviorState build() {
    _faceAnalyzer = FaceAnalyzer();
    _classifier = BehaviorClassifier();

    // Cleanup khi provider bị dispose
    ref.onDispose(() {
      _metricsTimer?.cancel();
      _behaviorEventController.close();
      _faceAnalyzer.dispose();
      _cameraService.dispose();
    });

    return const BehaviorState();
  }

  // ━━━━━━━━━━━━ PUBLIC METHODS ━━━━━━━━━━━━

  /// Bắt đầu monitoring — gọi khi phiên học bắt đầu
  Future<void> startMonitoring({bool useBackCamera = true}) async {
    try {
      state = state.copyWith(isMonitoring: false, error: null);

      // Khởi tạo camera
      await _cameraService.initialize(useBackCamera: useBackCamera);

      state = state.copyWith(
        isMonitoring: true,
        isBackCamera: useBackCamera,
      );

      _sessionStartTime = DateTime.now();
      _classifier.reset();

      // Bắt đầu stream ảnh → phân tích face → classify behavior
      final camera = _cameraService.controller!.description;
      await _cameraService.startImageStream((CameraImage image) {
        _processFrame(image, camera);
      });

      // Timer cập nhật metrics mỗi giây
      _metricsTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateMetrics(),
      );

      debugPrint('BehaviorMonitor: Started (${useBackCamera ? "BACK" : "FRONT"} camera)');
    } catch (e) {
      state = state.copyWith(
        isMonitoring: false,
        error: 'Không thể khởi tạo camera: $e',
      );
      debugPrint('BehaviorMonitor: Error starting: $e');
    }
  }

  /// Dừng monitoring — gọi khi phiên học kết thúc hoặc tạm dừng
  Future<void> stopMonitoring() async {
    _metricsTimer?.cancel();
    _metricsTimer = null;

    await _cameraService.stopImageStream();
    await _cameraService.dispose();

    state = state.copyWith(isMonitoring: false);
    debugPrint('BehaviorMonitor: Stopped');
  }

  /// Đổi camera (trước ↔ sau) ngay lập tức
  Future<void> switchCamera() async {
    if (!state.isMonitoring) return;

    await _cameraService.stopImageStream();
    await _cameraService.switchCamera();

    final camera = _cameraService.controller!.description;
    await _cameraService.startImageStream((CameraImage image) {
      _processFrame(image, camera);
    });

    state = state.copyWith(
      isBackCamera: _cameraService.isUsingBackCamera,
    );

    debugPrint(
      'BehaviorMonitor: Switched to ${state.isBackCamera ? "BACK" : "FRONT"} camera',
    );
  }

  // ━━━━━━━━━━━━ PRIVATE ━━━━━━━━━━━━

  /// Xử lý 1 frame ảnh: CameraImage → FaceAnalysis → BehaviorEvent
  Future<void> _processFrame(CameraImage image, CameraDescription camera) async {
    try {
      final faceAnalysis = await _faceAnalyzer.analyze(image, camera);
      final event = _classifier.classify(faceAnalysis);

      state = state.copyWith(
        currentBehavior: _classifier.currentBehavior,
        lastFaceAnalysis: faceAnalysis,
      );

      if (event != null) {
        _behaviorEventController.add(event);
        _recordEvent(event);
      }
    } catch (e) {
      debugPrint('BehaviorMonitor: Frame error: $e');
    } finally {
      _cameraService.markProcessingDone();
    }
  }

  void _recordEvent(BehaviorEvent event) {
    final m = state.metrics;
    final newHistory = [...m.history, event];
    int newCount = m.distractionCount;
    if (event.behavior != ChildBehavior.focused) newCount++;

    state = state.copyWith(
      metrics: m.copyWith(distractionCount: newCount, history: newHistory),
    );
  }

  void _updateMetrics() {
    if (_sessionStartTime == null) return;

    final m = state.metrics;
    final totalSec = DateTime.now().difference(_sessionStartTime!).inSeconds;
    int focusSec = m.totalFocusSeconds;
    if (state.currentBehavior == ChildBehavior.focused) focusSec++;

    final score = totalSec > 0 ? (focusSec / totalSec * 100) : 100.0;

    state = state.copyWith(
      metrics: m.copyWith(
        focusScore: score,
        totalFocusSeconds: focusSec,
        totalSessionSeconds: totalSec,
      ),
    );
  }
}
