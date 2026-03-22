import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import '../services/alarm_sound_service.dart';
import '../services/notification_service.dart';

class AlarmRingingScreen extends StatefulWidget {
  final String label;
  final String time;
  final String alarmId;
  final int snoozeMinutes;
  final String? soundName;
  final String? soundPath;

  const AlarmRingingScreen({
    super.key,
    required this.label,
    required this.time,
    required this.alarmId,
    this.snoozeMinutes = 10,
    this.soundName,
    this.soundPath,
  });

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with TickerProviderStateMixin {
  final AlarmSoundService _soundService = AlarmSoundService();
  late AnimationController _pulseController;
  late AnimationController _bellSwingController;
  late AnimationController _glowController;
  late AnimationController _colorController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bellSwingAnimation;
  late Animation<double> _glowAnimation;
  Timer? _vibrationTimer;
  bool _isDismissing = false;
  double _dismissProgress = 0.0;
  bool _vibrateEnabled = true;
  
  // Color animation
  int _currentColorIndex = 0;
  final List<List<Color>> _backgroundColors = [
    // Deep blue to purple
    [const Color(0xFF1A237E), const Color(0xFF283593), const Color(0xFF5C6BC0)],
    // Warm orange to red
    [const Color(0xFFE65100), const Color(0xFFF57C00), const Color(0xFFFFA726)],
    // Teal to cyan
    [const Color(0xFF006064), const Color(0xFF00838F), const Color(0xFF4DD0E1)],
    // Deep purple to pink
    [const Color(0xFF4A148C), const Color(0xFF6A1B9A), const Color(0xFFAB47BC)],
    // Green to lime
    [const Color(0xFF1B5E20), const Color(0xFF388E3C), const Color(0xFF7CB342)],
    // Red to pink
    [const Color(0xFFB71C1C), const Color(0xFFD32F2F), const Color(0xFFF06292)],
  ];

  @override
  void initState() {
    super.initState();

    // Pulse animation for the bell icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Bell swing animation
    _bellSwingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..repeat(reverse: true);
    _bellSwingAnimation = Tween<double>(begin: -0.15, end: 0.15).animate(
      CurvedAnimation(parent: _bellSwingController, curve: Curves.easeInOut),
    );

    // Glow ring animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_glowController);

    // Color change animation - changes every 3 seconds
    _colorController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _colorController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentColorIndex = (_currentColorIndex + 1) % _backgroundColors.length;
        });
        _colorController.forward(from: 0.0);
      }
    });
    _colorController.forward();

    _startAlarm();
  }

  Future<void> _startAlarm() async {
    // Find the alarm from provider to get the full config
    Alarm? alarm;
    try {
      final provider = context.read<AlarmProvider>();
      alarm = provider.alarms.firstWhere((a) => a.id == widget.alarmId);
    } catch (_) {
      // If not found, create a minimal alarm for sound playback
    }

    if (alarm != null) {
      _vibrateEnabled = alarm.vibrate;
      await _soundService.playAlarmSound(alarm);
    } else {
      // Fallback: create alarm using widget parameters (includes soundPath)
      final fallbackAlarm = Alarm(
        id: widget.alarmId,
        time: DateTime.now(),
        sound: widget.soundName ?? 'Default',
        soundPath: widget.soundPath ?? '',
      );
      await _soundService.playAlarmSound(fallbackAlarm);
    }

    // Start vibration pattern
    _startVibration();
  }

  void _startVibration() {
    if (!_vibrateEnabled) return;
    _vibrationTimer?.cancel();
    // Prefer real vibration (works better on locked screen); fall back to haptics.
    Vibration.hasVibrator().then((hasVibrator) {
      if (hasVibrator == true) {
        Vibration.vibrate(pattern: [0, 900, 300, 900, 300, 900], repeat: 0);
      } else {
        _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 200), () {
            HapticFeedback.heavyImpact();
          });
        });
        HapticFeedback.heavyImpact();
      }
    });
  }

  Future<void> _snooze() async {
    if (_isDismissing) return;
    _isDismissing = true;

    _vibrationTimer?.cancel();
    Vibration.cancel();
    await _soundService.stop();
    
    // Schedule snooze alarm
    await NotificationService().scheduleSnoozeAlarm(widget.alarmId, widget.snoozeMinutes);
    HapticFeedback.mediumImpact();
    
    if (mounted) {
      // Navigate to home route
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  Future<void> _dismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;

    _vibrationTimer?.cancel();
    Vibration.cancel();
    await _soundService.stop();
    HapticFeedback.lightImpact();
    
    if (mounted) {
      // Navigate to home route
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  void dispose() {
    _vibrationTimer?.cancel();
    Vibration.cancel();
    _pulseController.dispose();
    _bellSwingController.dispose();
    _glowController.dispose();
    _colorController.dispose();
    _soundService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorController,
      builder: (context, child) {
        final colors = _backgroundColors[_currentColorIndex];
        final nextIndex = (_currentColorIndex + 1) % _backgroundColors.length;
        final nextColors = _backgroundColors[nextIndex];
        
        // Interpolate between current and next colors
        final t = _colorController.value;
        final interpolatedColors = [
          Color.lerp(colors[0], nextColors[0], t)!,
          Color.lerp(colors[1], nextColors[1], t)!,
          Color.lerp(colors[2], nextColors[2], t)!,
        ];
        
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: interpolatedColors,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Time Display ──
                  Text(
                    widget.time,
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w100,
                      color: Colors.white,
                      letterSpacing: 4,
                      height: 1,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Text(
                      widget.label.isEmpty ? 'Alarm' : widget.label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.85),
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // ── Animated Bell with Glow ──
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow ring 1
                            _buildGlowRing(
                              size: 180 + (_glowAnimation.value * 30),
                              opacity: (1 - _glowAnimation.value) * 0.3,
                            ),
                            // Outer glow ring 2
                            _buildGlowRing(
                              size: 140 + (_glowAnimation.value * 50),
                              opacity: (1 - _glowAnimation.value) * 0.2,
                            ),
                            // Inner pulsing circle
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, _) {
                                return Container(
                                  width: 120 * _pulseAnimation.value,
                                  height: 120 * _pulseAnimation.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0.05),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Bell icon
                            AnimatedBuilder(
                              animation: _bellSwingAnimation,
                              builder: (context, _) {
                                return Transform.rotate(
                                  angle: _bellSwingAnimation.value,
                                  child: Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: const Icon(
                                      Icons.alarm_rounded,
                                      size: 72,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Action Buttons ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Snooze Button
                        _buildActionButton(
                          icon: Icons.snooze_rounded,
                          label: 'Snooze\n${widget.snoozeMinutes}min',
                          onTap: _snooze,
                          gradient: [
                            Colors.amber.withOpacity(0.4),
                            Colors.orange.withOpacity(0.3),
                          ],
                        ),

                        // Dismiss Button (larger)
                        _buildActionButton(
                          icon: Icons.alarm_off_rounded,
                          label: 'Dismiss',
                          onTap: _dismiss,
                          isPrimary: true,
                          gradient: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.15),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Swipe to dismiss hint
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Text(
                      'Tap to dismiss or snooze',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlowRing({required double size, required double opacity}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(opacity),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required List<Color> gradient,
    bool isPrimary = false,
  }) {
    final size = isPrimary ? 90.0 : 72.0;
    final iconSize = isPrimary ? 40.0 : 30.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                if (isPrimary)
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
              ],
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isPrimary ? 15 : 13,
              color: Colors.white.withOpacity(isPrimary ? 0.9 : 0.7),
              fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
