import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import '../widgets/ui_components.dart';
import '../widgets/time_gradient.dart';
import '../services/ringtone_picker_service.dart';
import '../services/alarm_sound_service.dart';

class AddEditAlarmScreen extends StatefulWidget {
  final Alarm? alarm;

  const AddEditAlarmScreen({super.key, this.alarm});

  @override
  State<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends State<AddEditAlarmScreen> {
  late TimeOfDay _selectedTime;
  late List<int> _repeatDays;
  late String _label;
  late String _soundName; // display name
  late String _soundPath; // actual path/url/key used for playback
  late bool _vibrate;
  late int _snoozeMinutes;
  
  final AlarmSoundService _soundService = AlarmSoundService();
  bool _isTesting = false;

  final List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<int> _snoozeOptions = [5, 10, 15];

  @override
  void initState() {
    super.initState();
    final alarm = widget.alarm;
    _selectedTime = alarm != null
        ? TimeOfDay(hour: alarm.time.hour, minute: alarm.time.minute)
        : TimeOfDay.now();
    _repeatDays = alarm?.repeatDays.toList() ?? [];
    _label = alarm?.label ?? '';
    _soundName = alarm?.sound ?? 'Default';
    _soundPath = (alarm?.soundPath.isNotEmpty ?? false)
        ? alarm!.soundPath
        : (alarm?.sound ?? 'Default');
    _vibrate = alarm?.vibrate ?? true;
    _snoozeMinutes = alarm?.snoozeMinutes ?? 10;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.alarm != null;

    return TimeBasedGradientBackground(
      changeIntervalSeconds: 10,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GradientIconButton(
            icon: Icons.close_rounded,
            size: 44,
            borderRadius: 10,
            gradientColors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.15)],
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isEditing ? 'Edit Alarm' : 'Add Alarm',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            GradientIconButton(
              icon: Icons.check_rounded,
              size: 44,
              borderRadius: 10,
              gradientColors: [const Color(0xFF00C853), const Color(0xFF00E676)],
              onPressed: _saveAlarm,
            ),
            const SizedBox(width: 16),
          ],
        ),
      body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            const SizedBox(height: 12),
            
            // Time Preview Card
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Large Time Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      _buildAnimatedTimeDigit(
                        (_selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod).toString().padLeft(2, '0'),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: const Text(
                          ':',
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      _buildAnimatedTimeDigit(
                        _selectedTime.minute.toString().padLeft(2, '0'),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.15)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedTime.period == DayPeriod.pm ? 'PM' : 'AM',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Time Picker Wheels
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hour Picker
                        SizedBox(
                          width: 70,
                          height: 140,
                          child: _buildWheelPicker(
                            items: List.generate(12, (i) => (i == 0 ? 12 : i).toString().padLeft(2, '0')),
                            selectedIndex: (_selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod) - 1,
                            onSelectedItemChanged: (index) {
                              final hour = (index + 1) > 12 ? (index + 1) - 12 : (index + 1) == 12 ? 12 : (index + 1);
                              final isPM = _selectedTime.period == DayPeriod.pm;
                              setState(() {
                                _selectedTime = TimeOfDay(
                                  hour: isPM ? (hour == 12 ? 12 : hour + 12) : (hour == 12 ? 0 : hour),
                                  minute: _selectedTime.minute,
                                );
                              });
                            },
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: const Text(
                            ':',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w300,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        // Minute Picker
                        SizedBox(
                          width: 70,
                          height: 140,
                          child: _buildWheelPicker(
                            items: List.generate(60, (i) => i.toString().padLeft(2, '0')),
                            selectedIndex: _selectedTime.minute,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedTime = TimeOfDay(
                                  hour: _selectedTime.hour,
                                  minute: index,
                                );
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // AM/PM Toggle
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPeriodChip('AM', _selectedTime.period == DayPeriod.am),
                            const SizedBox(height: 8),
                            _buildPeriodChip('PM', _selectedTime.period == DayPeriod.pm),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            // Test Alarm Button
            GradientButton(
              text: _isTesting ? 'Stop Test' : 'Test Alarm',
              icon: _isTesting ? Icons.stop_rounded : Icons.play_arrow_rounded,
              borderRadius: 12,
              gradientColors: _isTesting 
                  ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)]
                  : [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.15)],
              onPressed: _testAlarm,
            ),

            const SizedBox(height: 24),

            // Settings Section Header
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 16),
              child: Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            
            // Repeat - Modern weekday chips
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(Icons.repeat_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Repeat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _repeatDaysText,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final isSelected = _repeatDays.contains(index);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _repeatDays.remove(index);
                            } else {
                              _repeatDays.add(index);
                              _repeatDays.sort();
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: isSelected 
                                ? LinearGradient(
                                    colors: [Colors.white.withOpacity(0.4), Colors.white.withOpacity(0.2)],
                                  )
                                : null,
                            color: isSelected ? null : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected 
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.white.withOpacity(0.25),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _dayNames[index].substring(0, 1),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : Colors.white54,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            _buildGlassTile(
              icon: Icons.label_outline_rounded,
              title: 'Label',
              value: _label.isEmpty ? 'Alarm' : _label,
              onTap: () => _showLabelDialog(),
            ),
            
            _buildGlassTile(
              icon: Icons.music_note_outlined,
              title: 'Sound',
              value: _soundName,
              onTap: () async {
                final result = await RingtonePickerService.showRingtonePicker(context);
                if (result != null) {
                  setState(() {
                    _soundName = result.name;
                    _soundPath = result.path;
                  });
                }
              },
            ),
            
            // Snooze Duration - Feature C
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(Icons.snooze_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Snooze',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_snoozeMinutes} min',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: _snoozeOptions.map((minutes) {
                      final isSelected = _snoozeMinutes == minutes;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _snoozeMinutes = minutes),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: minutes != _snoozeOptions.last ? 10 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: isSelected 
                                  ? LinearGradient(
                                      colors: [Colors.white.withOpacity(0.4), Colors.white.withOpacity(0.2)],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.white.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$minutes min',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Vibrate Switch
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.vibration_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Vibrate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  GradientToggle(
                    value: _vibrate,
                    onChanged: (value) => setState(() => _vibrate = value),
                    activeColors: [Colors.white.withOpacity(0.4), Colors.white.withOpacity(0.2)],
                    width: 52,
                    height: 28,
                  ),
                ],
              ),
            ),

            if (isEditing) ...[
              const SizedBox(height: 24),
              GradientButton(
                text: 'Delete Alarm',
                icon: Icons.delete_outline_rounded,
                gradientColors: [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
                onPressed: _deleteAlarm,
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTimeDigit(String digit) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(digit),
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.5, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWheelPicker({
    required List<String> items,
    required int selectedIndex,
    required Function(int) onSelectedItemChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: FixedExtentScrollController(initialItem: selectedIndex),
      itemExtent: 50,
      perspective: 0.005,
      diameterRatio: 1.5,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: items.length,
        builder: (context, index) {
          final isSelected = index == selectedIndex;
          return Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 32 : 24,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected 
                    ? Colors.white
                    : Colors.white.withOpacity(0.4),
              ),
              child: Text(items[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodChip(String period, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          final hour = _selectedTime.hour;
          if (period == 'AM' && hour >= 12) {
            _selectedTime = TimeOfDay(hour: hour - 12, minute: _selectedTime.minute);
          } else if (period == 'PM' && hour < 12) {
            _selectedTime = TimeOfDay(hour: hour + 12, minute: _selectedTime.minute);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 44,
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.3)],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Colors.white.withOpacity(0.8)
                : Colors.white.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: isSelected ? 20 : 16,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
            letterSpacing: 1,
          ),
          child: Text(period),
        ),
      ),
    );
  }

  Widget _buildGlassTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }

  String get _repeatDaysText {
    if (_repeatDays.isEmpty) return 'Never';
    if (_repeatDays.length == 7) return 'Every day';
    if (_repeatDays.length == 5 &&
        !_repeatDays.contains(5) && !_repeatDays.contains(6)) return 'Weekdays';
    if (_repeatDays.length == 2 &&
        _repeatDays.contains(5) && _repeatDays.contains(6)) return 'Weekends';
    return _repeatDays.map((d) => _dayNames[d]).join(', ');
  }

  void _showLabelDialog() {
    final controller = TextEditingController(text: _label);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 32),
            child: GlassCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.15)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Alarm Label',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Give your alarm a name',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter label',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GradientButton(
                          text: 'Cancel',
                          height: 48,
                          borderRadius: 12,
                          gradientColors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.08)],
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientButton(
                          text: 'Save',
                          height: 48,
                          borderRadius: 12,
                          gradientColors: [const Color(0xFF4A90D9), const Color(0xFF7B68EE)],
                          onPressed: () {
                            setState(() => _label = controller.text);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _saveAlarm() {
    final now = DateTime.now();
    final alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final alarm = Alarm(
      id: widget.alarm?.id ?? const Uuid().v4(),
      time: alarmTime,
      repeatDays: _repeatDays,
      label: _label,
      sound: _soundName,
      soundPath: _soundPath,
      isEnabled: widget.alarm?.isEnabled ?? true,
      vibrate: _vibrate,
      snoozeMinutes: _snoozeMinutes,
    );

    // Save alarm data
    final provider = context.read<AlarmProvider>();
    () async {
      try {
        if (widget.alarm != null) {
          await provider.updateAlarm(alarm);
        } else {
          await provider.addAlarm(alarm);
        }
      } catch (e) {
        debugPrint('AddEditAlarmScreen: saveAlarm error: $e');
      }
      if (mounted) {
        Navigator.pop(context);
      }
    }();
  }

  void _deleteAlarm() {
    final id = widget.alarm!.id;
    () async {
      try {
        await context.read<AlarmProvider>().deleteAlarm(id);
      } catch (e) {
        debugPrint('AddEditAlarmScreen: deleteAlarm error: $e');
      }
      if (mounted) {
        Navigator.pop(context);
      }
    }();
  }

  Future<void> _testAlarm() async {
    if (_isTesting) {
      await _soundService.stop();
      setState(() => _isTesting = false);
      return;
    }

    setState(() => _isTesting = true);
    
    // Vibrate if enabled
    if (_vibrate) {
      HapticFeedback.vibrate();
    }
    
    // Play the actual selected sound using AlarmSoundService
    final testAlarm = Alarm(
      id: 'test',
      time: DateTime.now(),
      sound: _soundName,
      soundPath: _soundPath,
      vibrate: _vibrate,
    );
    await _soundService.playAlarmSound(testAlarm, loop: true);
    
    // Show test dialog with blur
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: GlassCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.15)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.alarm, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Testing Alarm',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sound: $_soundName',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _vibrate ? Icons.vibration_rounded : Icons.vibration_outlined,
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _vibrate ? 'Vibration On' : 'Vibration Off',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                GradientButton(
                  text: 'Stop Test',
                  width: 140,
                  height: 48,
                  borderRadius: 12,
                  gradientColors: [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
                  onPressed: () async {
                    await _soundService.stop();
                    if (mounted) Navigator.pop(context);
                    setState(() => _isTesting = false);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _soundService.stop();
    super.dispose();
  }
}
