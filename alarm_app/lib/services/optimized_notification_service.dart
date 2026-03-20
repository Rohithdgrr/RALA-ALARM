import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';
import '../models/alarm.dart';

/// Optimized Notification Service with caching and batch operations
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Cache for notification details to avoid recreating them
  final Map<String, NotificationDetails> _detailsCache = HashMap();
  
  // Batch operation queue for better performance
  final List<Future<void>> _pendingOperations = [];
  Timer? _batchTimer;

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
    );

    final android = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to alarm ringing screen
  }

  /// Fast alarm scheduling with caching
  Future<void> scheduleAlarm(Alarm alarm) async {
    final now = DateTime.now();
    final scheduledDate = _calculateNextAlarmTime(alarm, now);
    
    if (scheduledDate == null) return;

    final notificationId = alarm.id.hashCode;
    final details = _getCachedNotificationDetails(alarm);

    if (alarm.repeatDays.isEmpty) {
      await _notifications.zonedSchedule(
        notificationId,
        alarm.label.isEmpty ? 'Alarm' : alarm.label,
        'Tap to dismiss',
        tz.TZDateTime.from(scheduledDate, local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      return;
    }

    for (final day in alarm.repeatDays) {
      final daysUntilNext = (day - now.weekday + 1 + 7) % 7;
      var nextDate = scheduledDate.add(Duration(days: daysUntilNext));
      if (nextDate.isBefore(now)) {
        nextDate = nextDate.add(const Duration(days: 7));
      }

      await _notifications.zonedSchedule(
        notificationId + day,
        alarm.label.isEmpty ? 'Alarm' : alarm.label,
        'Tap to dismiss',
        tz.TZDateTime.from(nextDate, local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// Batch schedule multiple alarms efficiently
  Future<void> scheduleAlarmsBatch(List<Alarm> alarms) async {
    final now = DateTime.now();
    final futures = <Future<void>>[];
    
    for (final alarm in alarms) {
      if (!alarm.isEnabled) continue;
      
      final scheduledDate = _calculateNextAlarmTime(alarm, now);
      if (scheduledDate == null) continue;

      final notificationId = alarm.id.hashCode;
      final details = _getCachedNotificationDetails(alarm);

      futures.add(
        _notifications.zonedSchedule(
          notificationId,
          alarm.label.isEmpty ? 'Alarm' : alarm.label,
          'Tap to dismiss',
          tz.TZDateTime.from(scheduledDate, local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        ),
      );
    }
    
    // Execute all in parallel
    await Future.wait(futures, eagerError: false);
  }

  /// Calculate next alarm time efficiently
  DateTime? _calculateNextAlarmTime(Alarm alarm, DateTime now) {
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

    if (alarm.repeatDays.isEmpty) {
      return scheduledDate;
    }

    // Find nearest repeat day
    DateTime? nearestDate;
    for (final day in alarm.repeatDays) {
      final daysUntilNext = (day - now.weekday + 1 + 7) % 7;
      var nextDate = scheduledDate.add(Duration(days: daysUntilNext));
      if (nextDate.isBefore(now)) {
        nextDate = nextDate.add(const Duration(days: 7));
      }
      if (nearestDate == null || nextDate.isBefore(nearestDate)) {
        nearestDate = nextDate;
      }
    }
    return nearestDate;
  }

  /// Get cached notification details for faster lookup
  NotificationDetails _getCachedNotificationDetails(Alarm alarm) {
    final cacheKey = '${alarm.sound}_${alarm.vibrate}_${alarm.fadeInVolume}';
    
    if (_detailsCache.containsKey(cacheKey)) {
      return _detailsCache[cacheKey]!;
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_channel',
        'Alarms',
        channelDescription: 'Alarm notifications',
        importance: Importance.max,
        priority: Priority.max,
        playSound: false, // Sound handled by AlarmSoundService
        enableVibration: alarm.vibrate,
        vibrationPattern: alarm.vibrate ? Int64List.fromList([0, 1000, 500, 1000]) : null,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        onlyAlertOnce: false,
        showWhen: true,
        usesChronometer: false,
      ),
      iOS: DarwinNotificationDetails(
        sound: 'alarm_sound.mp3',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    _detailsCache[cacheKey] = details;
    return details;
  }

  /// Fast cancel with batch support
  Future<void> cancelAlarm(String id) async {
    final notificationId = id.hashCode;
    await _notifications.cancel(notificationId);

    for (int day = 0; day < 7; day++) {
      await _notifications.cancel(notificationId + day);
    }
  }

  /// Batch cancel multiple alarms
  Future<void> cancelAlarmsBatch(List<String> ids) async {
    final futures = ids.map((id) => _notifications.cancel(id.hashCode));
    await Future.wait(futures, eagerError: false);
  }

  /// Show immediate alarm notification (for when alarm triggers)
  Future<void> showAlarmRinging(String title, {String? soundPath}) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch,
      title,
      'Tap to dismiss',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_ringing_channel',
          'Alarm Ringing',
          channelDescription: 'Alarm is ringing',
          importance: Importance.max,
          priority: Priority.max,
          playSound: false, // Sound handled by AlarmSoundService
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          ongoing: true,
          autoCancel: false,
        ),
        iOS: DarwinNotificationDetails(
          sound: soundPath ?? 'alarm_sound.mp3',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
    );
  }

  Future<void> dismissAlarm() async {
    await _notifications.cancelAll();
    _detailsCache.clear();
  }

  /// Clear cache when memory is needed
  void clearCache() {
    _detailsCache.clear();
  }
}
