# 📋 HANDOVER DOCUMENT — Học Cùng Trẻ Em
**Ngày:** 2026-04-10 19:14 (GMT+7)

---

## 📍 Đang làm: Phase 05 → Phase 06 (AI Tutor)
## 🔢 Đến bước: Phase 05 DONE, Phase 06 chưa bắt đầu

---

## ✅ ĐÃ XONG (5/10 phases — 50%):

| Phase | Trang thái | Chi tiết |
|-------|-----------|----------|
| Phase 01: Setup | ✅ 100% | Flutter 3.29.3, Clean Architecture, Material 3, 72+ packages |
| Phase 02: Behavior Detection | ✅ 100% | CameraService, FaceAnalyzer (ML Kit), BehaviorClassifier (5 states), Temporal smoothing |
| Phase 03: Session Manager | ✅ 100% | State Machine (6 states), Pomodoro Timer, Presets (Toán/TV/Tự do), CircularTimer widget |
| Phase 04: Audio Reminder | ✅ 100% | EscalationManager (5 levels), MessageGenerator (75+ msgs), SmartTTS (vi-VN), VoiceClone stub |
| Phase 05: OCR & Image | ✅ 100% | OcrService (ML Kit), SubjectDetector, ImageCapture, CaptureScreen + OcrPreview UI |

## ⏳ CÒN LẠI (5 phases):

| Phase | Mô tả |
|-------|-------|
| **Phase 06: AI Tutor** | Gemini 2.5 Flash API integration, chat UI, multimodal (text + ảnh) |
| Phase 07: Parent Dashboard | Focus history, session reports, charts |
| Phase 08: Settings | Child profiles, voice clone setup, camera preferences |
| Phase 09: UI Polish | Animations, transitions, loading states, empty states |
| Phase 10: Testing | Unit tests, widget tests, integration tests |

## 🔧 QUYẾT ĐỊNH QUAN TRỌNG:
- Material Design 3 cho TOÀN BỘ app (không tách style trẻ em / người lớn)
- Camera SAU là default (trẻ nhìn sách, không nhìn điện thoại)
- Riverpod 3.x Notifier API (KHÔNG dùng StateNotifier deprecated)
- Google TTS vi-VN là default, Voice Clone (Pocket-TTS) là optional future
- 75+ static messages (15×5 levels) + anti-repeat tracking

## ⚠️ LƯU Ý CHO SESSION SAU:
- **Env vars phải set trước khi chạy Flutter:**
  ```powershell
  $env:JAVA_HOME='G:\jdk-17.0.13+11'
  $env:ANDROID_HOME='G:\android-sdk'
  $env:Path+=';G:\flutter\bin;G:\jdk-17.0.13+11\bin'
  ```
- `.env` chứa `github_token` và `GEMINI_API_KEY` — ĐÃ được gitignore
- Git push trên PowerShell luôn exit code 1 (stderr), nhưng output xác nhận thành công
- Phase 06 cần GEMINI_API_KEY từ `.env` để gọi Gemini 2.5 Flash API

## 📁 FILES QUAN TRỌNG:
- `plans/260410-1457-hoc-cung-tre-em/plan.md` — Master plan
- `plans/260410-1457-hoc-cung-tre-em/phase-06a-ai-tutor-cloud.md` — Next phase spec
- `docs/design-specs.md` — Material Design 3 specs
- `.brain/brain.json` — Static knowledge
- `.brain/session.json` — Dynamic session (gitignored)
- `.env` — API keys (gitignored)

## 📊 Code Stats:
- **Total source files:** ~25 Dart files
- **Total lines:** ~4,800+ lines
- **Git commits:** 7 on `main`
- **GitHub:** https://github.com/TuanVOID/hoc-cung-tre-em
- **flutter analyze:** ✅ No issues found

---
📍 Đã lưu! Để tiếp tục: Gõ `/recap`
