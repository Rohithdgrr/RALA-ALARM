class Alarm {
  final String id;
  final DateTime time;
  final List<int> repeatDays; // 0-6 for Monday-Sunday
  final String label;
  final String sound; // Display name of the sound (also used as key for in-app ringtones)
  final String soundPath; // Actual file path, URL, or same as sound for in-app
  final bool isEnabled;
  final bool vibrate;
  final int snoozeMinutes; // 5, 10, or 15
  final bool fadeInVolume; // Gradually increase volume
  final bool useRandomRingtone; // Different sound each day
  final bool requirePowerConnected; // Only ring when charging
  final double initialVolume; // Starting volume for fade-in (0.0 - 1.0)

  Alarm({
    required this.id,
    required this.time,
    this.repeatDays = const [],
    this.label = '',
    this.sound = 'Default',
    this.soundPath = '',
    this.isEnabled = true,
    this.vibrate = true,
    this.snoozeMinutes = 10,
    this.fadeInVolume = false,
    this.useRandomRingtone = false,
    this.requirePowerConnected = false,
    this.initialVolume = 0.1,
  });

  Alarm copyWith({
    String? id,
    DateTime? time,
    List<int>? repeatDays,
    String? label,
    String? sound,
    String? soundPath,
    bool? isEnabled,
    bool? vibrate,
    int? snoozeMinutes,
    bool? fadeInVolume,
    bool? useRandomRingtone,
    bool? requirePowerConnected,
    double? initialVolume,
  }) {
    return Alarm(
      id: id ?? this.id,
      time: time ?? this.time,
      repeatDays: repeatDays ?? this.repeatDays,
      label: label ?? this.label,
      sound: sound ?? this.sound,
      soundPath: soundPath ?? this.soundPath,
      isEnabled: isEnabled ?? this.isEnabled,
      vibrate: vibrate ?? this.vibrate,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      fadeInVolume: fadeInVolume ?? this.fadeInVolume,
      useRandomRingtone: useRandomRingtone ?? this.useRandomRingtone,
      requirePowerConnected: requirePowerConnected ?? this.requirePowerConnected,
      initialVolume: initialVolume ?? this.initialVolume,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time.toIso8601String(),
      'repeatDays': repeatDays,
      'label': label,
      'sound': sound,
      'soundPath': soundPath,
      'isEnabled': isEnabled,
      'vibrate': vibrate,
      'snoozeMinutes': snoozeMinutes,
      'fadeInVolume': fadeInVolume,
      'useRandomRingtone': useRandomRingtone,
      'requirePowerConnected': requirePowerConnected,
      'initialVolume': initialVolume,
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String,
      time: DateTime.parse(json['time'] as String),
      repeatDays: List<int>.from(json['repeatDays'] as List),
      label: json['label'] as String? ?? '',
      sound: json['sound'] as String? ?? 'Default',
      soundPath: json['soundPath'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
      vibrate: json['vibrate'] as bool? ?? true,
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 10,
      fadeInVolume: json['fadeInVolume'] as bool? ?? false,
      useRandomRingtone: json['useRandomRingtone'] as bool? ?? false,
      requirePowerConnected: json['requirePowerConnected'] as bool? ?? false,
      initialVolume: json['initialVolume'] as double? ?? 0.1,
    );
  }

  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedPeriod {
    return time.hour >= 12 ? 'PM' : 'AM';
  }

  String get formattedTimeWithPeriod {
    int hour = time.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String get repeatDaysText {
    if (repeatDays.isEmpty) return 'Never';
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (repeatDays.length == 7) return 'Every day';
    if (repeatDays.length == 5 && 
        !repeatDays.contains(5) && !repeatDays.contains(6)) return 'Weekdays';
    if (repeatDays.length == 2 && 
        repeatDays.contains(5) && repeatDays.contains(6)) return 'Weekends';
    return repeatDays.map((d) => dayNames[d]).join(', ');
  }
}
