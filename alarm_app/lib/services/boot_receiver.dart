import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/alarm.dart';
import 'notification_service.dart';

/// Boot receiver that reschedules alarms after device reboot
class BootReceiver {
  static const MethodChannel _channel = MethodChannel('com.example.alarm_app/boot');
  
  /// Initialize boot receiver and listen for boot events
  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    
    _channel.setMethodCallHandler(_handleMethodCall);
  }
  
  /// Handle boot completed event
  static Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onBootCompleted') {
      await _rescheduleAlarms();
    }
  }
  
  /// Reschedule all enabled alarms from storage
  static Future<void> _rescheduleAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getStringList('alarms') ?? [];
      
      final alarms = alarmsJson
          .map((json) => Alarm.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .where((alarm) => alarm.isEnabled)
          .toList();
      
      // Reschedule all enabled alarms
      for (final alarm in alarms) {
        await NotificationService().scheduleAlarm(alarm);
      }
      
      debugPrint('Rescheduled ${alarms.length} alarms after boot');
    } catch (e) {
      debugPrint('Error rescheduling alarms after boot: $e');
    }
  }
}
