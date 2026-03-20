import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import '../services/notification_service.dart';

class AlarmProvider extends ChangeNotifier {
  List<Alarm> _alarms = [];
  final NotificationService _notificationService = NotificationService();

  List<Alarm> get alarms => _alarms;
  List<Alarm> get enabledAlarms => _alarms.where((a) => a.isEnabled).toList();

  AlarmProvider() {
    loadAlarms();
  }

  Future<void> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList('alarms') ?? [];
    _alarms = alarmsJson
        .map((json) => Alarm.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
    
    // Reschedule all enabled alarms
    for (final alarm in _alarms) {
      if (alarm.isEnabled) {
        await _scheduleAlarm(alarm);
      }
    }
    
    notifyListeners();
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = _alarms.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('alarms', alarmsJson);
  }

  Future<void> addAlarm(Alarm alarm) async {
    _alarms.add(alarm);
    await _saveAlarms();
    if (alarm.isEnabled) {
      await _scheduleAlarm(alarm);
    }
    notifyListeners();
  }

  Future<void> updateAlarm(Alarm alarm) async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = alarm;
      await _saveAlarms();
      await _notificationService.cancelAlarm(alarm.id);
      if (alarm.isEnabled) {
        await _scheduleAlarm(alarm);
      }
      notifyListeners();
    }
  }

  Future<void> deleteAlarm(String id) async {
    _alarms.removeWhere((a) => a.id == id);
    await _saveAlarms();
    await _notificationService.cancelAlarm(id);
    notifyListeners();
  }

  Future<void> toggleAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      _alarms[index] = _alarms[index].copyWith(isEnabled: !_alarms[index].isEnabled);
      await _saveAlarms();
      if (_alarms[index].isEnabled) {
        await _scheduleAlarm(_alarms[index]);
      } else {
        await _notificationService.cancelAlarm(id);
      }
      notifyListeners();
    }
  }

  Future<void> _scheduleAlarm(Alarm alarm) async {
    await _notificationService.scheduleAlarm(alarm);
  }
}
