/// App-wide constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Học Cùng Trẻ Em';
  static const String appVersion = '0.1.0';

  // Session defaults
  static const int defaultSessionMinutes = 20;
  static const int defaultBreakMinutes = 5;
  static const int maxSessionsPerDay = 4;

  // Behavior detection thresholds
  static const double headRotationThreshold = 30.0; // Quay đầu > 30° = mất tập trung
  static const double eyeOpenThreshold = 0.3; // Mắt nhắm < 0.3 = buồn ngủ
  static const int absentTimeoutSeconds = 5; // Mất mặt > 5s = rời chỗ
  static const int distractionCooldownSeconds = 10; // Cooldown giữa 2 lần nhắc

  // Audio reminder
  static const int maxEscalationLevel = 5;
  static const double ttsSpeedRate = 0.45; // Chậm, rõ cho trẻ

  // Camera
  static const int cameraFps = 10;
  static const int cameraWidth = 640;
  static const int cameraHeight = 480;
}
