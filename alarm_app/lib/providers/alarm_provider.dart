import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import '../services/notification_service.dart';
import '../services/home_widget_service.dart';

class AlarmProvider extends ChangeNotifier {
  List<Alarm> _alarms = [];
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;

  List<Alarm> get alarms => _alarms;
  List<Alarm> get enabledAlarms => _alarms.where((a) => a.isEnabled).toList();
  bool get isLoading => _isLoading;

  AlarmProvider() {
    // Don't auto-load in constructor - let main.dart handle it
  }

  Future<void> loadAlarms() async {
    if (_isLoading) return; // Prevent double loading
    _isLoading = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getStringList('alarms') ?? [];
      _alarms = alarmsJson
          .map((json) => Alarm.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();
      
      notifyListeners();
      
      // Reschedule all enabled alarms in background (non-blocking)
      _rescheduleAlarmsInBackground();
    } catch (e) {
      debugPrint('Error loading alarms: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _rescheduleAlarmsInBackground() async {
    try {
      for (final alarm in _alarms) {
        if (alarm.isEnabled) {
          await _scheduleAlarm(alarm);
        }
      }
      await HomeWidgetProvider.updateWidget(_alarms);
    } catch (e) {
      debugPrint('Background reschedule error: $e');
    }
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = _alarms.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('alarms', alarmsJson);
  }

  /// Add alarm - instantly updates UI, schedules in background
  Future<void> addAlarm(Alarm alarm) async {
    _alarms.add(alarm);
    await _saveAlarms();
    notifyListeners();
    
    // Schedule and update widget in background to prevent UI delay
    _addAlarmInBackground(alarm);
  }

  Future<void> _addAlarmInBackground(Alarm alarm) async {
    try {
      if (alarm.isEnabled) {
        await _scheduleAlarm(alarm);
      }
      await HomeWidgetProvider.updateWidget(_alarms);
    } catch (e) {
      debugPrint('Background alarm scheduling error: $e');
    }
  }

  /// Update alarm - instantly updates UI, reschedules in background
  Future<void> updateAlarm(Alarm alarm) async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = alarm;
      await _saveAlarms();
      notifyListeners();
      
      // Cancel old and schedule new in background
      _updateAlarmInBackground(alarm);
    }
  }

  Future<void> _updateAlarmInBackground(Alarm alarm) async {
    try {
      await _notificationService.cancelAlarm(alarm.id);
      if (alarm.isEnabled) {
        await _scheduleAlarm(alarm);
      }
      await HomeWidgetProvider.updateWidget(_alarms);
    } catch (e) {
      debugPrint('Background alarm update error: $e');
    }
  }

  /// Delete alarm - instantly updates UI, cancels in background
  Future<void> deleteAlarm(String id) async {
    _alarms.removeWhere((a) => a.id == id);
    await _saveAlarms();
    notifyListeners();
    
    // Cancel notification and update widget in background
    _deleteAlarmInBackground(id);
  }

  Future<void> _deleteAlarmInBackground(String id) async {
    try {
      await _notificationService.cancelAlarm(id);
      await HomeWidgetProvider.updateWidget(_alarms);
    } catch (e) {
      debugPrint('Background alarm deletion error: $e');
    }
  }

  /// Toggle alarm - instantly updates UI, reschedules in background
  Future<void> toggleAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      _alarms[index] = _alarms[index].copyWith(isEnabled: !_alarms[index].isEnabled);
      await _saveAlarms();
      notifyListeners();
      
      // Toggle notification in background
      _toggleAlarmInBackground(id, _alarms[index]);
    }
  }

  Future<void> _toggleAlarmInBackground(String id, Alarm alarm) async {
    try {
      if (alarm.isEnabled) {
        await _scheduleAlarm(alarm);
      } else {
        await _notificationService.cancelAlarm(id);
      }
      await HomeWidgetProvider.updateWidget(_alarms);
    } catch (e) {
      debugPrint('Background alarm toggle error: $e');
    }
  }

  Future<void> _scheduleAlarm(Alarm alarm) async {
    await _notificationService.scheduleAlarm(alarm);
  }
}
