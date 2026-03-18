<div align="center">

# ⏰ Alarm App

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
| 📱 **Notifications** | Scheduled local notifications with full-screen intent |
| 🔍 **Search** | Find alarms quickly |
| ⚙️ **Settings** | Dark mode, theme customization |
| 🎨 **Animations** | Smooth transitions, gradient backgrounds, pulsing effects |

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
│   ├── alarm_provider.dart
│   └── optimized_alarm_provider.dart
├── screens/
│   ├── alarm_list_screen.dart
│   ├── add_edit_alarm_screen.dart
│   ├── sound_picker_screen.dart
│   ├── alarm_ringing_screen.dart
│   └── settings_screen.dart
├── services/
│   ├── notification_service.dart
│   ├── alarm_sound_service.dart
│   ├── battery_service.dart
│   ├── boot_receiver.dart
│   └── ringtone_picker_service.dart
└── widgets/
    ├── animated_background.dart
    ├── dark_mode_backgrounds.dart
    ├── enhanced_animations.dart
    └── ui_components.dart
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

</details>

---

<div align="center">

**Made with ❤️ using Flutter**

</div>
