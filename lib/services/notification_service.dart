import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';
import '../models/alarm.dart';
import '../screens/alarm_ringing_screen.dart';
import '../main.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Store alarm data for when notification is tapped
  final Map<String, Alarm> _scheduledAlarms = {};
  
  // Timer to handle alarm triggers when app is in foreground
  Timer? _alarmCheckTimer;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );

    // Request runtime permissions on Android
    final android = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    
    // Create notification channels
    await _createNotificationChannels();
    
    // Start alarm check timer for foreground mode
    _startAlarmCheckTimer();
  }
  
  Future<void> _createNotificationChannels() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    // Alarm channel with full-screen intent
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'alarm_channel',
        'Alarms',
        description: 'Alarm notifications with full-screen intent',
        importance: Importance.max,
        playSound: false, // We play sound ourselves via AlarmSoundService
        enableVibration: true,
      ),
    );
    
    // Ringing channel
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'alarm_ringing_channel',
        'Alarm Ringing',
        description: 'Active alarm ringing',
        importance: Importance.max,
        playSound: false, // We play sound ourselves
        enableVibration: true,
      ),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;
    
    // Parse payload - format: "alarmId|label|time|snoozeMinutes|soundName"
    final parts = response.payload!.split('|');
    final alarmId = parts[0];
    final label = parts.length > 1 ? parts[1] : '';
    final time = parts.length > 2 ? parts[2] : '';
    final snoozeMinutes = parts.length > 3 ? int.tryParse(parts[3]) ?? 10 : 10;
    final soundName = parts.length > 4 ? parts[4] : 'Default';
    
    // Navigate to alarm ringing screen
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => AlarmRingingScreen(
          label: label,
          time: time,
          alarmId: alarmId,
          snoozeMinutes: snoozeMinutes,
          soundName: soundName,
        ),
      ),
      (route) => route.isFirst,
    );
  }
  
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    // Handle background notification tap - will be processed when app opens
  }
  
  /// Start timer to check for scheduled alarms every second
  void _startAlarmCheckTimer() {
    _alarmCheckTimer?.cancel();
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAndTriggerAlarms();
    });
  }
  
  /// Check if any alarm should trigger now
  void _checkAndTriggerAlarms() {
    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
    
    for (final entry in _scheduledAlarms.entries) {
      final alarm = entry.value;
      if (!alarm.isEnabled) continue;
      
      final alarmTime = TimeOfDay(hour: alarm.time.hour, minute: alarm.time.minute);
      
      // Check if alarm time matches current time (within 1 minute window)
      if (currentTime.hour == alarmTime.hour && currentTime.minute == alarmTime.minute) {
        // Check if we should trigger today (for repeating alarms)
        if (alarm.repeatDays.isEmpty || alarm.repeatDays.contains(now.weekday - 1)) {
          _triggerAlarm(alarm);
        }
      }
    }
  }
  
  /// Directly trigger alarm ringing screen
  void _triggerAlarm(Alarm alarm) {
    // Show notification first
    showAlarmRinging(alarm.label.isEmpty ? '⏰ Alarm' : '⏰ ${alarm.label}', alarm.id);
    
    // Also directly navigate to alarm ringing screen if app is in foreground
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => AlarmRingingScreen(
          label: alarm.label,
          time: alarm.formattedTimeWithPeriod,
          alarmId: alarm.id,
          snoozeMinutes: alarm.snoozeMinutes,
          soundName: alarm.sound,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  /// Build a rich payload string that encodes all alarm info
  String _buildPayload(Alarm alarm) {
    return '${alarm.id}|${alarm.label}|${alarm.formattedTimeWithPeriod}|${alarm.snoozeMinutes}|${alarm.sound}';
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Store alarm for notification tap handling
    _scheduledAlarms[alarm.id] = alarm;
    
    final payload = _buildPayload(alarm);

    if (alarm.repeatDays.isEmpty) {
      // One-time alarm
      await _notifications.zonedSchedule(
        alarm.id.hashCode,
        alarm.label.isEmpty ? '⏰ Alarm' : '⏰ ${alarm.label}',
        'Tap to open alarm',
        tz.TZDateTime.from(scheduledDate, local),
        _getNotificationDetails(alarm),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } else {
      // Repeating alarm - schedule for each day
      for (final day in alarm.repeatDays) {
        final daysUntilNext = (day - now.weekday + 1 + 7) % 7;
        var nextDate = scheduledDate.add(Duration(days: daysUntilNext));
        if (nextDate.isBefore(now)) {
          nextDate = nextDate.add(const Duration(days: 7));
        }
        await _notifications.zonedSchedule(
          alarm.id.hashCode + day,
          alarm.label.isEmpty ? '⏰ Alarm' : '⏰ ${alarm.label}',
          'Tap to open alarm',
          tz.TZDateTime.from(nextDate, local),
          _getNotificationDetails(alarm),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
        );
      }
    }
  }

  NotificationDetails _getNotificationDetails(Alarm alarm) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_channel',
        'Alarms',
        channelDescription: 'Alarm notifications',
        importance: Importance.max,
        priority: Priority.max,
        playSound: false, // Sound is handled by AlarmSoundService
        enableVibration: alarm.vibrate,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        ongoing: true,
        autoCancel: false,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'snooze',
            'Snooze',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'dismiss',
            'Dismiss',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      ),
    );
  }

  Future<void> showAlarmRinging(String title, String alarmId) async {
    final alarm = _scheduledAlarms[alarmId];
    final payload = alarm != null ? _buildPayload(alarm) : alarmId;
    
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      'Tap to dismiss',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_ringing_channel',
          'Alarm Ringing',
          channelDescription: 'Alarm is ringing',
          importance: Importance.max,
          priority: Priority.max,
          playSound: false,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          ongoing: true,
          autoCancel: false,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'dismiss',
              'Dismiss',
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> scheduleSnoozeAlarm(String originalAlarmId, int snoozeMinutes) async {
    final alarm = _scheduledAlarms[originalAlarmId];
    if (alarm == null) return;
    
    final snoozeId = '${originalAlarmId}_snooze';
    final scheduledTime = DateTime.now().add(Duration(minutes: snoozeMinutes));
    final payload = _buildPayload(alarm);
    
    await _notifications.zonedSchedule(
      snoozeId.hashCode,
      alarm.label.isEmpty ? '⏰ Snooze' : '⏰ ${alarm.label} (Snooze)',
      'Snooze alarm',
      tz.TZDateTime.from(scheduledTime, local),
      _getNotificationDetails(alarm),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelAlarm(String id) async {
    await _notifications.cancel(id.hashCode);
    // Cancel repeating alarms too
    for (int day = 0; day < 7; day++) {
      await _notifications.cancel(id.hashCode + day);
    }
    // Cancel any snooze
    await _notifications.cancel('${id}_snooze'.hashCode);
    _scheduledAlarms.remove(id);
  }

  Future<void> dismissAlarm() async {
    await _notifications.cancelAll();
    _scheduledAlarms.clear();
  }
  
  // Load alarms from storage and reschedule after reboot
  Future<void> rescheduleAllAlarms(List<Alarm> alarms) async {
    await _notifications.cancelAll();
    _scheduledAlarms.clear();
    
    for (final alarm in alarms) {
      if (alarm.isEnabled) {
        await scheduleAlarm(alarm);
      }
    }
  }
  
  /// Dispose resources
  void dispose() {
    _alarmCheckTimer?.cancel();
    _alarmCheckTimer = null;
  }
}
