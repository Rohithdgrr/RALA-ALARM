import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyAlarmDuration = 'alarm_duration';
  static const String _keyDefaultSnooze = 'default_snooze';
  static const String _keyRingtonePath = 'ringtone_path';
  static const String _keyWallpaperPath = 'wallpaper_path';

  bool _isDarkMode = false;
  int _alarmDurationMinutes = 5;
  int _defaultSnoozeMinutes = 10;
  String _ringtonePath = '';
  String _wallpaperPath = '';

  bool get isDarkMode => _isDarkMode;
  int get alarmDurationMinutes => _alarmDurationMinutes;
  int get defaultSnoozeMinutes => _defaultSnoozeMinutes;
  String get ringtonePath => _ringtonePath;
  String get wallpaperPath => _wallpaperPath;

  AppSettings() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_keyThemeMode) ?? false;
    _alarmDurationMinutes = prefs.getInt(_keyAlarmDuration) ?? 5;
    _defaultSnoozeMinutes = prefs.getInt(_keyDefaultSnooze) ?? 10;
    _ringtonePath = prefs.getString(_keyRingtonePath) ?? '';
    _wallpaperPath = prefs.getString(_keyWallpaperPath) ?? '';
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyThemeMode, value);
    notifyListeners();
  }

  Future<void> setAlarmDuration(int minutes) async {
    _alarmDurationMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAlarmDuration, minutes);
    notifyListeners();
  }

  Future<void> setDefaultSnooze(int minutes) async {
    _defaultSnoozeMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDefaultSnooze, minutes);
    notifyListeners();
  }

  Future<void> setRingtonePath(String path) async {
    _ringtonePath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRingtonePath, path);
    notifyListeners();
  }

  Future<void> setWallpaperPath(String path) async {
    _wallpaperPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWallpaperPath, path);
    notifyListeners();
  }
}
