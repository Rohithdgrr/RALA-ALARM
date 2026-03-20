import 'package:flutter/material.dart';
import '../models/alarm.dart';

class AlarmPresets {
  static final List<AlarmPreset> presets = [
    AlarmPreset(
      name: 'Workout',
      icon: Icons.fitness_center,
      color: const Color(0xFFFF6B6B),
      hour: 6,
      minute: 0,
      label: 'Time to exercise!',
      repeatDays: [0, 1, 2, 3, 4], // Mon-Fri
      sound: 'energetic',
      vibrate: true,
    ),
    AlarmPreset(
      name: 'Meeting',
      icon: Icons.business,
      color: const Color(0xFF4ECDC4),
      hour: 9,
      minute: 0,
      label: 'Meeting reminder',
      repeatDays: [0, 1, 2, 3, 4], // Mon-Fri
      sound: 'professional',
      vibrate: true,
    ),
    AlarmPreset(
      name: 'Nap',
      icon: Icons.bedtime,
      color: const Color(0xFF7B68EE),
      hour: 14,
      minute: 0,
      label: 'Power nap time',
      repeatDays: [],
      sound: 'gentle',
      vibrate: false,
    ),
    AlarmPreset(
      name: 'Study',
      icon: Icons.school,
      color: const Color(0xFFFFD93D),
      hour: 19,
      minute: 0,
      label: 'Study session',
      repeatDays: [0, 1, 2, 3, 4, 5, 6], // Daily
      sound: 'calm',
      vibrate: true,
    ),
    AlarmPreset(
      name: 'Bedtime',
      icon: Icons.nights_stay,
      color: const Color(0xFF6C5CE7),
      hour: 22,
      minute: 30,
      label: 'Time to sleep',
      repeatDays: [0, 1, 2, 3, 4, 5, 6], // Daily
      sound: 'soft',
      vibrate: false,
    ),
    AlarmPreset(
      name: 'Weekend',
      icon: Icons.weekend,
      color: const Color(0xFF00B894),
      hour: 9,
      minute: 30,
      label: 'Weekend morning',
      repeatDays: [5, 6], // Sat-Sun
      sound: 'nature',
      vibrate: true,
    ),
  ];

  static Alarm createAlarmFromPreset(AlarmPreset preset) {
    final now = DateTime.now();
    return Alarm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      time: DateTime(now.year, now.month, now.day, preset.hour, preset.minute),
      repeatDays: preset.repeatDays,
      label: preset.label,
      sound: preset.sound,
      isEnabled: true,
      vibrate: preset.vibrate,
      snoozeMinutes: 10,
    );
  }
}

class AlarmPreset {
  final String name;
  final IconData icon;
  final Color color;
  final int hour;
  final int minute;
  final String label;
  final List<int> repeatDays;
  final String sound;
  final bool vibrate;

  AlarmPreset({
    required this.name,
    required this.icon,
    required this.color,
    required this.hour,
    required this.minute,
    required this.label,
    required this.repeatDays,
    required this.sound,
    required this.vibrate,
  });
}
