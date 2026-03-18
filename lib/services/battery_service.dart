import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BatteryService extends ChangeNotifier {
  final Battery _battery = Battery();
  BatteryState _state = BatteryState.unknown;
  int _level = 100;
  StreamSubscription<BatteryState>? _stateSubscription;

  BatteryState get state => _state;
  int get level => _level;
  bool get isLowBattery => _level <= 20;
  bool get isCharging => _state == BatteryState.charging;
  bool get isFull => _state == BatteryState.full;

  BatteryService() {
    _initBattery();
  }

  Future<void> _initBattery() async {
    // Get initial battery level
    _level = await _battery.batteryLevel;
    
    // Listen to battery state changes
    _stateSubscription = _battery.onBatteryStateChanged.listen((state) {
      _state = state;
      notifyListeners();
      _checkLowBattery();
    });

    notifyListeners();
  }

  void _checkLowBattery() {
    if (isLowBattery && !isCharging) {
      // Trigger low battery warning
      HapticService.warningPattern();
    }
  }

  Future<bool> checkPowerConnected() async {
    return isCharging || isFull;
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    super.dispose();
  }
}

class HapticService {
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  static void vibrate() {
    HapticFeedback.vibrate();
  }

  // Custom vibration patterns
  static void alarmPattern() async {
    for (int i = 0; i < 3; i++) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  static void snoozePattern() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    HapticFeedback.lightImpact();
  }

  static void dismissPattern() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
  }

  static void togglePattern() {
    HapticFeedback.selectionClick();
  }

  static void successPattern() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    HapticFeedback.heavyImpact();
  }

  static void warningPattern() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
  }

  static void errorPattern() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
  }
}
