import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/alarm.dart';

class HomeWidgetProvider {
  static const String appGroupId = 'group.com.example.alarm_app';
  static const String widgetName = 'AlarmWidget';
  static const String iOSWidgetName = 'AlarmWidget';
  static const String androidWidgetName = 'AlarmWidget';

  static bool _initialized = false;
  static bool _initAttempted = false;

  static Future<void> init() async {
    if (_initialized || _initAttempted) return;
    _initAttempted = true;
    
    try {
      // Set timeout for home widget initialization
      await HomeWidget.setAppGroupId(appGroupId).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('HomeWidgetProvider: Init timed out');
          return false;
        },
      );
      _initialized = true;
      debugPrint('HomeWidgetProvider: Initialized successfully');
    } catch (e) {
      debugPrint('HomeWidgetProvider: Init error: $e');
      // Don't rethrow - widget is optional feature
    }
  }

  /// Update Android widget with alarm data
  static Future<void> updateWidget(List<Alarm> alarms) async {
    try {
      if (!_initialized) {
        await init();
      }
      
      // Skip if widget couldn't be initialized
      if (!_initialized) {
        debugPrint('HomeWidgetProvider: Skipping update - widget not initialized');
        return;
      }
      
      final enabledAlarms = alarms.where((a) => a.isEnabled).toList();
      final nextAlarm = _getNextAlarm(enabledAlarms);
      
      // Save widget data with error handling for each operation
      try {
        await HomeWidget.saveWidgetData('alarm_count', enabledAlarms.length.toString());
      } catch (e) {
        debugPrint('HomeWidgetProvider: Error saving alarm_count: $e');
      }
      
      if (nextAlarm != null) {
        try {
          await HomeWidget.saveWidgetData('next_alarm_time', nextAlarm.formattedTimeWithPeriod);
          await HomeWidget.saveWidgetData('next_alarm_label', nextAlarm.label.isEmpty ? 'Alarm' : nextAlarm.label);
        } catch (e) {
          debugPrint('HomeWidgetProvider: Error saving alarm details: $e');
        }
      } else {
        try {
          await HomeWidget.saveWidgetData('next_alarm_time', 'No alarms');
          await HomeWidget.saveWidgetData('next_alarm_label', 'Tap to set');
        } catch (e) {
          debugPrint('HomeWidgetProvider: Error saving empty state: $e');
        }
      }
      
      // Update the widget
      try {
        await HomeWidget.updateWidget(
          name: widgetName,
          androidName: androidWidgetName,
          iOSName: iOSWidgetName,
        );
        debugPrint('HomeWidgetProvider: Widget updated - ${enabledAlarms.length} alarms');
      } catch (e) {
        debugPrint('HomeWidgetProvider: Update widget error: $e');
      }
    } catch (e) {
      debugPrint('HomeWidgetProvider: Update error: $e');
    }
  }

  static Alarm? _getNextAlarm(List<Alarm> alarms) {
    if (alarms.isEmpty) return null;
    
    final now = DateTime.now();
    Alarm? nextAlarm;
    DateTime? nextTime;
    
    for (final alarm in alarms) {
      var alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        alarm.time.hour,
        alarm.time.minute,
      );
      
      // Calculate next occurance
      if (alarm.repeatDays.isNotEmpty) {
        // For repeating alarms, find the next day
        int daysUntil = 7; // Start with a week
        for (int i = 0; i < 7; i++) {
          final checkDay = (now.weekday - 1 + i) % 7;
          if (alarm.repeatDays.contains(checkDay)) {
            final candidateTime = alarmTime.add(Duration(days: i));
            if (candidateTime.isAfter(now) && i < daysUntil) {
              daysUntil = i;
            }
          }
        }
        if (daysUntil < 7) {
          alarmTime = alarmTime.add(Duration(days: daysUntil));
        } else {
          // All repeat days have passed, find the earliest next week
          for (int i = 0; i < 7; i++) {
            final checkDay = (now.weekday - 1 + i) % 7;
            if (alarm.repeatDays.contains(checkDay)) {
              alarmTime = alarmTime.add(Duration(days: i));
              break;
            }
          }
        }
      } else {
        // One-time alarm
        if (!alarmTime.isAfter(now)) {
          alarmTime = alarmTime.add(const Duration(days: 1));
        }
      }
      
      if (nextTime == null || alarmTime.isBefore(nextTime)) {
        nextTime = alarmTime;
        nextAlarm = alarm;
      }
    }
    
    return nextAlarm;
  }
}
