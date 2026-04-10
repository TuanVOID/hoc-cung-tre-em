import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hoc_cung_tre_em/core/constants/app_constants.dart';
import 'package:hoc_cung_tre_em/core/services/message_generator.dart';

/// SmartTtsService — TTS engine có priority chain:
///   1. Voice Clone (Pocket-TTS) — nếu đã setup + thiết bị đủ mạnh
///   2. Google TTS (flutter_tts) — luôn available, fallback
///
/// Voice Clone sẽ được tích hợp ở version sau khi native bridge sẵn sàng.
/// Hiện tại dùng Google TTS (tiếng Việt rất tốt trên Android).
class SmartTtsService {
  SmartTtsService._();
  static final SmartTtsService instance = SmartTtsService._();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// Voice clone có available không? (future implementation)
  bool _voiceCloneAvailable = false;

  bool get isSpeaking => _isSpeaking;
  bool get voiceCloneAvailable => _voiceCloneAvailable;

  // ━━━━━━━━━━━━ LIFECYCLE ━━━━━━━━━━━━

  /// Khởi tạo TTS engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Cấu hình Google TTS
    await _flutterTts.setLanguage('vi-VN');
    await _flutterTts.setSpeechRate(AppConstants.ttsSpeedRate);
    await _flutterTts.setVolume(0.9);

    // Callbacks
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      debugPrint('TTS Error: $msg');
    });

    _isInitialized = true;
    debugPrint('SmartTTS: Initialized (vi-VN, rate=${AppConstants.ttsSpeedRate})');
  }

  // ━━━━━━━━━━━━ PUBLIC API ━━━━━━━━━━━━

  /// Phát giọng nói — ưu tiên Voice Clone, fallback Google TTS
  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();

    // Không phát chồng chéo
    if (_isSpeaking) {
      await stop();
    }

    // Priority 1: Voice Clone (future implementation)
    if (_voiceCloneAvailable) {
      try {
        await _speakWithVoiceClone(text);
        return;
      } catch (e) {
        debugPrint('SmartTTS: Voice clone failed, falling back to Google TTS');
      }
    }

    // Priority 2: Google TTS (luôn available)
    await _speakWithGoogleTts(text);
  }

  /// Phát với pitch điều chỉnh theo level nhắc nhở
  /// Pitch cao = nhẹ nhàng, pitch thấp = nghiêm
  Future<void> speakWithLevel(String text, ReminderLevel level) async {
    final pitch = _levelPitch(level);
    final rate = _levelRate(level);

    await _flutterTts.setPitch(pitch);
    await _flutterTts.setSpeechRate(rate);

    await speak(text);

    // Reset về default sau khi nói xong
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(AppConstants.ttsSpeedRate);
  }

  /// Dừng phát
  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  /// Giải phóng tài nguyên
  Future<void> dispose() async {
    await stop();
    _isInitialized = false;
  }

  // ━━━━━━━━━━━━ VOICE CLONE (Placeholder) ━━━━━━━━━━━━

  /// TODO: Implement khi Pocket-TTS native bridge sẵn sàng
  /// Hiện tại chức năng này chưa active, luôn fallback Google TTS
  Future<void> _speakWithVoiceClone(String text) async {
    // Future implementation:
    // 1. Load voice profile từ Hive
    // 2. Synthesize qua Pocket-TTS native channel
    // 3. Play audio output
    throw UnimplementedError('Voice clone not yet available');
  }

  /// Đánh dấu voice clone đã setup (gọi từ Voice Setup Screen)
  void setVoiceCloneAvailable(bool available) {
    _voiceCloneAvailable = available;
    debugPrint('SmartTTS: Voice clone ${available ? "ENABLED" : "DISABLED"}');
  }

  // ━━━━━━━━━━━━ GOOGLE TTS ━━━━━━━━━━━━

  Future<void> _speakWithGoogleTts(String text) async {
    await _flutterTts.speak(text);
    debugPrint('SmartTTS: Speaking → "$text"');
  }

  // ━━━━━━━━━━━━ TUNING ━━━━━━━━━━━━

  /// Pitch theo level: cao = dịu, thấp = nghiêm
  double _levelPitch(ReminderLevel level) {
    return switch (level) {
      ReminderLevel.gentle => 1.1,
      ReminderLevel.firm => 1.0,
      ReminderLevel.serious => 0.95,
      ReminderLevel.strict => 0.9,
      ReminderLevel.critical => 0.85,
    };
  }

  /// Speed rate theo level: nghiêm = nói chậm hơn
  double _levelRate(ReminderLevel level) {
    return switch (level) {
      ReminderLevel.gentle => 0.45,
      ReminderLevel.firm => 0.45,
      ReminderLevel.serious => 0.42,
      ReminderLevel.strict => 0.40,
      ReminderLevel.critical => 0.38,
    };
  }
}
