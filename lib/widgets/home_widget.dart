import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';

class HomeWidgetService {
  static const String _appGroupId = 'group.com.example.alarmapp';
  static const String _widgetName = 'AlarmWidget';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateWidget(AlarmProvider provider) async {
    final alarms = provider.alarms;
    final nextAlarm = _getNextAlarm(alarms);
    final alarmCount = alarms.where((a) => a.isEnabled).length;

    await HomeWidget.saveWidgetData('next_alarm_time', nextAlarm?.formattedTimeWithPeriod ?? 'No alarms');
    await HomeWidget.saveWidgetData('next_alarm_label', nextAlarm?.label ?? '');
    await HomeWidget.saveWidgetData('alarm_count', alarmCount.toString());
    await HomeWidget.saveWidgetData('has_alarms', (alarmCount > 0).toString());

    await HomeWidget.updateWidget(
      name: _widgetName,
      iOSName: _widgetName,
    );
  }

  static Alarm? _getNextAlarm(List<Alarm> alarms) {
    final now = DateTime.now();
    Alarm? soonest;
    DateTime? soonestTime;

    for (final alarm in alarms) {
      if (!alarm.isEnabled) continue;

      DateTime? nextTime;
      final base = DateTime(now.year, now.month, now.day, alarm.time.hour, alarm.time.minute);

      if (alarm.repeatDays.isEmpty) {
        nextTime = base.isAfter(now) ? base : base.add(const Duration(days: 1));
      } else {
        for (final repeatDay in alarm.repeatDays) {
          final targetWeekday = repeatDay + 1;
          final delta = (targetWeekday - now.weekday + 7) % 7;
          var candidate = base.add(Duration(days: delta));
          if (!candidate.isAfter(now)) {
            candidate = candidate.add(const Duration(days: 7));
          }
          if (nextTime == null || candidate.isBefore(nextTime)) {
            nextTime = candidate;
          }
        }
      }

      if (nextTime != null && (soonestTime == null || nextTime.isBefore(soonestTime))) {
        soonestTime = nextTime;
        soonest = alarm;
      }
    }

    return soonest;
  }
}

// Widget UI Components
class AlarmWidgetView extends StatelessWidget {
  final String nextAlarmTime;
  final String nextAlarmLabel;
  final int alarmCount;
  final bool hasAlarms;

  const AlarmWidgetView({
    super.key,
    required this.nextAlarmTime,
    required this.nextAlarmLabel,
    required this.alarmCount,
    required this.hasAlarms,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                alarmCount > 0 ? '$alarmCount alarms' : 'No alarms',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasAlarms) ...[
            Text(
              nextAlarmTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (nextAlarmLabel.isNotEmpty)
              Text(
                nextAlarmLabel,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ] else ...[
            const Text(
              'Tap to add',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class QuickToggleWidget extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onToggle;

  const QuickToggleWidget({
    super.key,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
                  colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
                )
              : null,
          color: isEnabled ? null : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEnabled ? Icons.alarm_on : Icons.alarm_off,
              color: isEnabled ? Colors.white : Colors.black54,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isEnabled ? 'ON' : 'OFF',
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
