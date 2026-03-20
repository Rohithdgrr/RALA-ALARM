<div align="center">

# ⏰ RALA Alarm

**A beautiful, feature-rich alarm app built with Flutter**

<img src="https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter" alt="Flutter">
<img src="https://img.shields.io/badge/Platform-Android-green?style=for-the-badge" alt="Platform">
<img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License">

</div>

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 📋 **Alarm List** | View all alarms with toggle switches & next alarm info |
| ➕ **Add/Edit Alarm** | Set time, repeat days, label, sound & vibration |
| 🎵 **Sound Picker** | Choose from **In-App** ringtones, **Local** files, or **YouTube** links |
| 🔔 **Alarm Ringing** | Full-screen alarm with snooze, dismiss, and animated effects |
| 🔄 **Pull to Refresh** | Refresh alarm list with gesture |
| 📱 **Notifications** | Single notification with dismiss/snooze actions |
| 🏠 **Home Widget** | View next alarm and active alarm count on home screen |
| 🔍 **Search** | Find alarms quickly |
| ⚙️ **Settings** | Dark mode, theme customization |
| 🎨 **Animations** | Smooth transitions, gradient backgrounds, pulsing effects |
| 🚀 **Boot Recovery** | Restores alarms after device reboot |

---

## 🎨 Design

- **Gradient backgrounds** (Time-based colors)
- **Blue accent** (#4A90D9)
- **Large time display**
- **Sharp-bordered icons**
- **Animated toggle switches**
- **Glass-morphism cards**

---

## 🚀 Quick Start

```bash
# Navigate to project
cd alarm_app

# Install dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Install to emulator/device
flutter install
```

---

## 📁 Project Structure

```
lib/
├── main.dart
├── models/
│   ├── alarm.dart
│   └── app_settings.dart
├── providers/
│   └── alarm_provider.dart
├── screens/
│   ├── alarm_list_screen.dart
│   ├── add_edit_alarm_screen.dart
│   ├── sound_picker_screen.dart
│   ├── alarm_ringing_screen.dart
│   ├── settings_screen.dart
│   ├── splash_screen.dart
│   └── onboarding_screen.dart
├── services/
│   ├── notification_service.dart
│   ├── alarm_sound_service.dart
│   ├── battery_service.dart
│   ├── boot_receiver.dart
│   ├── home_widget_service.dart
│   └── ringtone_picker_service.dart
└── widgets/
    └── ui_components.dart

android/
├── app/src/main/kotlin/com/example/alarm_app/
│   ├── MainActivity.kt
│   └── AlarmWidget.kt
└── app/src/main/res/
    ├── layout/alarm_widget.xml
    └── xml/alarm_widget_info.xml
```

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `flutter_local_notifications` | Alarm notifications |
| `shared_preferences` | Persist alarms |
| `audioplayers` | Play alarm sounds |
| `file_picker` | Select local audio files |
| `google_fonts` | Typography |
| `timezone` | Timezone support |
| `home_widget` | Home screen widget |
| `battery_plus` | Battery optimization |
| `uuid` | Unique alarm IDs |

---

## 🔐 Permissions

<details>
<summary><b>Android</b></summary>

- `SCHEDULE_EXACT_ALARM` - Schedule exact alarms
- `USE_EXACT_ALARM` - Android 14+ exact alarm permission
- `RECEIVE_BOOT_COMPLETED` - Restore alarms after reboot
- `VIBRATE` - Vibrate on alarm
- `POST_NOTIFICATIONS` - Show notifications
- `FOREGROUND_SERVICE` - Keep alarm service running
- `WAKE_LOCK` - Wake device on alarm
- `FOREGROUND_SERVICE_SPECIAL_USE` - Special foreground service

</details>

---

## 🏠 Home Screen Widget

The app includes a home screen widget that displays:
- **Active alarm count**
- **Next alarm time**
- **Next alarm label**

Tap the widget to open the app directly.

---

## 🔔 Notification Features

- **Single notification** - No duplicate notifications when alarm triggers
- **Dismiss action** - Stop alarm directly from notification
- **Snooze action** - Snooze alarm from notification panel
- **Full-screen intent** - Opens alarm ringing screen automatically

---

## 📱 Recent Updates

### Bug Fixes
- Fixed black screen after dismissing alarm
- Fixed alarm stuck at splash screen after first use
- Fixed multiple notification issue - now shows single notification per alarm
- Fixed shrinking alarm ringing screen layout
- Fixed dismiss/snooze button functionality in notifications

### New Features
- Added home screen widget for quick alarm overview
- Updated logo to `logo RALA.png`
- Added custom alarm icon in notification panel
- Improved splash screen with notification handling
- Added home widget sync on all alarm operations

---

## 🛠️ Building

### Requirements
- Flutter SDK 3.0+
- Android SDK
- Kotlin 1.7+

### Build Commands

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# Install to connected device
flutter install

# Run on emulator
flutter run
```

---

## 📝 Notes

- The app uses `home_widget` package version 0.6.0 for widget functionality
- Notification actions (dismiss/snooze) work from the notification panel
- Alarms are restored automatically after device reboot
- Sound playback is handled by `AlarmSoundService` rather than system notification sounds

---

<div align="center">

**Made with ❤️ using Flutter**

</div>
