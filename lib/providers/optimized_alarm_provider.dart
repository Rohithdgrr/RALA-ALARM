import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import '../services/optimized_notification_service.dart';

/// Optimized Alarm Provider with caching and batch operations
class OptimizedAlarmProvider extends ChangeNotifier {
  List<Alarm> _alarms = [];
  final NotificationService _notificationService = NotificationService();
  
  // Fast lookup caches
  final Map<String, Alarm> _alarmCache = HashMap();
  final Map<String, bool> _enabledCache = HashMap();
  
  // Debounce timer for save operations
  Timer? _saveDebounceTimer;
  bool _isLoading = false;
  bool _hasPendingChanges = false;

  List<Alarm> get alarms => List.unmodifiable(_alarms);
  List<Alarm> get enabledAlarms => _alarms.where((a) => a.isEnabled).toList();
  bool get isLoading => _isLoading;

  OptimizedAlarmProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadAlarms();
  }

  /// Fast alarm loading with caching
  Future<void> loadAlarms() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getStringList('alarms') ?? [];
      
      // Parse alarms in parallel for better performance
      _alarms = await compute(_parseAlarmsIsolate, alarmsJson);
      
      // Rebuild caches
      _rebuildCache();
      
      // Schedule all enabled alarms in batch
      await _batchScheduleEnabledAlarms();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Parse alarms in isolate for better performance
  static List<Alarm> _parseAlarmsIsolate(List<String> alarmsJson) {
    return alarmsJson
        .map((json) => Alarm.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  /// Rebuild internal caches
  void _rebuildCache() {
    _alarmCache.clear();
    _enabledCache.clear();
    
    for (final alarm in _alarms) {
      _alarmCache[alarm.id] = alarm;
      _enabledCache[alarm.id] = alarm.isEnabled;
    }
  }

  /// Batch schedule all enabled alarms efficiently
  Future<void> _batchScheduleEnabledAlarms() async {
    final enabledAlarms = _alarms.where((a) => a.isEnabled).toList();
    if (enabledAlarms.isEmpty) return;
    
    await _notificationService.scheduleAlarmsBatch(enabledAlarms);
  }

  /// Fast alarm lookup by ID
  Alarm? getAlarmById(String id) => _alarmCache[id];

  /// Check if alarm is enabled (fast cache lookup)
  bool isAlarmEnabled(String id) => _enabledCache[id] ?? false;

  /// Add alarm with debounced save
  Future<void> addAlarm(Alarm alarm) async {
    _alarms.add(alarm);
    _alarmCache[alarm.id] = alarm;
    _enabledCache[alarm.id] = alarm.isEnabled;
    
    if (alarm.isEnabled) {
      await _notificationService.scheduleAlarm(alarm);
    }
    
    _debouncedSave();
    notifyListeners();
  }

  /// Update alarm efficiently
  Future<void> updateAlarm(Alarm alarm) async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index == -1) return;

    _alarms[index] = alarm;
    _alarmCache[alarm.id] = alarm;
    _enabledCache[alarm.id] = alarm.isEnabled;

    // Cancel and reschedule
    await _notificationService.cancelAlarm(alarm.id);
    if (alarm.isEnabled) {
      await _notificationService.scheduleAlarm(alarm);
    }

    _debouncedSave();
    notifyListeners();
  }

  /// Fast toggle with immediate feedback
  Future<void> toggleAlarm(String id) async {
    final alarm = _alarmCache[id];
    if (alarm == null) return;

    final newEnabled = !alarm.isEnabled;
    final updatedAlarm = alarm.copyWith(isEnabled: newEnabled);

    // Update immediately for UI responsiveness
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      _alarms[index] = updatedAlarm;
      _alarmCache[id] = updatedAlarm;
      _enabledCache[id] = newEnabled;
    }

    notifyListeners();

    // Background operations
    if (newEnabled) {
      await _notificationService.scheduleAlarm(updatedAlarm);
    } else {
      await _notificationService.cancelAlarm(id);
    }

    _debouncedSave();
  }

  /// Delete alarm efficiently
  Future<void> deleteAlarm(String id) async {
    _alarms.removeWhere((a) => a.id == id);
    _alarmCache.remove(id);
    _enabledCache.remove(id);

    await _notificationService.cancelAlarm(id);
    _debouncedSave();
    notifyListeners();
  }

  /// Debounced save to reduce SharedPreferences writes
  void _debouncedSave() {
    _hasPendingChanges = true;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _saveAlarms();
    });
  }

  /// Save alarms to SharedPreferences
  Future<void> _saveAlarms() async {
    if (!_hasPendingChanges) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = _alarms.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList('alarms', alarmsJson);
      _hasPendingChanges = false;
    } catch (e) {
      debugPrint('Error saving alarms: $e');
    }
  }

  /// Force immediate save (for app shutdown)
  Future<void> forceSave() async {
    _saveDebounceTimer?.cancel();
    await _saveAlarms();
  }

  /// Get next alarm time efficiently
  DateTime? getNextAlarmTime() {
    final now = DateTime.now();
    DateTime? soonest;

    for (final alarm in _alarms) {
      if (!alarm.isEnabled) continue;
      
      final next = _calculateNextOccurrence(alarm, now);
      if (next != null && (soonest == null || next.isBefore(soonest))) {
        soonest = next;
      }
    }
    return soonest;
  }

  /// Calculate next occurrence for an alarm
  DateTime? _calculateNextOccurrence(Alarm alarm, DateTime now) {
    var base = DateTime(now.year, now.month, now.day, alarm.time.hour, alarm.time.minute);

    if (alarm.repeatDays.isEmpty) {
      if (base.isAfter(now)) return base;
      return base.add(const Duration(days: 1));
    }

    DateTime? best;
    for (final repeatDay in alarm.repeatDays) {
      final targetWeekday = repeatDay + 1;
      final delta = (targetWeekday - now.weekday + 7) % 7;
      var candidate = base.add(Duration(days: delta));
      if (!candidate.isAfter(now)) {
        candidate = candidate.add(const Duration(days: 7));
      }
      if (best == null || candidate.isBefore(best)) {
        best = candidate;
      }
    }
    return best;
  }

  /// Refresh all scheduled alarms (call after device restart)
  Future<void> refreshAllAlarms() async {
    await _batchScheduleEnabledAlarms();
  }

  /// Clear caches when memory is low
  void clearCaches() {
    _notificationService.clearCache();
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    forceSave();
    super.dispose();
  }
}
