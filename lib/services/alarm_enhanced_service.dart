import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';

class MissedAlarmService {
  static const String _keyDismissedAlarms = 'dismissed_alarms';
  static const String _keyMissedAlarms = 'missed_alarms';

  // Track when alarm was triggered
  static Future<void> markAlarmTriggered(String alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('triggered_$alarmId', now);
  }

  // Mark alarm as dismissed
  static Future<void> markAlarmDismissed(String alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('triggered_$alarmId');
    
    final dismissed = prefs.getStringList(_keyDismissedAlarms) ?? [];
    if (!dismissed.contains(alarmId)) {
      dismissed.add(alarmId);
      await prefs.setStringList(_keyDismissedAlarms, dismissed);
    }
  }

  // Check for missed alarms
  static Future<List<String>> checkMissedAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final missed = <String>[];
    
    // Get all keys that start with 'triggered_'
    final keys = prefs.getKeys().where((k) => k.startsWith('triggered_'));
    
    for (final key in keys) {
      final triggeredTime = prefs.getInt(key);
      if (triggeredTime != null) {
        final elapsed = DateTime.now().millisecondsSinceEpoch - triggeredTime;
        // If more than 5 minutes passed without dismissal
        if (elapsed > 5 * 60 * 1000) {
          final alarmId = key.replaceFirst('triggered_', '');
          missed.add(alarmId);
          
          // Add to missed alarms list
          final missedList = prefs.getStringList(_keyMissedAlarms) ?? [];
          if (!missedList.contains(alarmId)) {
            missedList.add(alarmId);
            await prefs.setStringList(_keyMissedAlarms, missedList);
          }
        }
      }
    }
    
    return missed;
  }

  // Get missed alarm count
  static Future<int> getMissedAlarmCount() async {
    final prefs = await SharedPreferences.getInstance();
    final missed = prefs.getStringList(_keyMissedAlarms) ?? [];
    return missed.length;
  }

  // Clear missed alarm history
  static Future<void> clearMissedAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMissedAlarms);
  }

  // Check if alarm should ring (considering power connected only option)
  static Future<bool> shouldAlarmRing(Alarm alarm) async {
    if (!alarm.requirePowerConnected) return true;
    
    // Check if power is connected
    // This would integrate with BatteryService
    return true; // Simplified for now
  }
}

class FadeInAudioService {
  static const double _startVolume = 0.1;
  static const double _maxVolume = 1.0;
  static const int _fadeDurationSeconds = 30;
  
  Timer? _fadeTimer;
  double _currentVolume = _startVolume;
  Function(double)? _onVolumeChanged;

  void startFadeIn(Function(double) onVolumeChanged) {
    _onVolumeChanged = onVolumeChanged;
    _currentVolume = _startVolume;
    _onVolumeChanged?.call(_currentVolume);
    
    final steps = _fadeDurationSeconds * 2; // Update every 500ms
    final increment = (_maxVolume - _startVolume) / steps;
    var step = 0;
    
    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      step++;
      _currentVolume = _startVolume + (increment * step);
      
      if (_currentVolume >= _maxVolume || step >= steps) {
        _currentVolume = _maxVolume;
        timer.cancel();
      }
      
      _onVolumeChanged?.call(_currentVolume);
    });
  }

  void stopFadeIn() {
    _fadeTimer?.cancel();
    _currentVolume = _startVolume;
  }

  double get currentVolume => _currentVolume;
}

class RandomRingtoneService {
  static final List<String> _ringtones = [
    'morning_birds',
    'ocean_waves',
    'gentle_chimes',
    'soft_piano',
    'nature_sounds',
    'meditation_bell',
    'sunrise_guitar',
    'peaceful_flute',
  ];

  static String getRandomRingtone() {
    final dayOfYear = DateTime.now().day;
    final index = dayOfYear % _ringtones.length;
    return _ringtones[index];
  }

  static String getRingtoneForDate(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final index = dayOfYear % _ringtones.length;
    return _ringtones[index];
  }

  static List<String> get allRingtones => List.unmodifiable(_ringtones);
}
