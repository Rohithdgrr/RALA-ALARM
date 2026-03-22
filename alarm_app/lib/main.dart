import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tzcore;
import 'package:home_widget/home_widget.dart';
import 'models/app_settings.dart';
import 'providers/alarm_provider.dart';
import 'screens/alarm_list_screen.dart';
import 'services/battery_service.dart';
import 'services/notification_service.dart';
import 'services/boot_receiver.dart';
import 'services/home_widget_service.dart';
import 'dart:async';

// Global navigator key for navigation from notification service
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezones
  try {
    tz.initializeTimeZones();
    tzcore.setLocalLocation(tzcore.local);
  } catch (e) {
    debugPrint('Timezone init error: $e');
  }
  
  // Initialize home widget service (for Android widgets)
  try {
    await HomeWidget.setAppGroupId('group.com.example.alarm_app').timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        debugPrint('HomeWidget setAppGroupId timed out');
        return false;
      },
    );
  } catch (e) {
    debugPrint('HomeWidget init error: $e');
  }
  
  // Initialize notification service with timeout
  NotificationService? notificationService;
  try {
    notificationService = NotificationService();
    await notificationService.initialize().timeout(
      const Duration(seconds: 3),
      onTimeout: () => debugPrint('Notification init timed out'),
    );
  } catch (e) {
    debugPrint('Notification init error: $e');
  }
  
  // Initialize boot receiver with timeout
  try {
    await BootReceiver.initialize().timeout(
      const Duration(seconds: 2),
      onTimeout: () => debugPrint('BootReceiver init timed out'),
    );
  } catch (e) {
    debugPrint('BootReceiver init error: $e');
  }
  
  // Load and reschedule all alarms on app start with timeout
  final alarmProvider = AlarmProvider();
  try {
    await alarmProvider.loadAlarms().timeout(
      const Duration(seconds: 3),
      onTimeout: () => debugPrint('Alarm load timed out'),
    );
  } catch (e) {
    debugPrint('Alarm load error: $e');
  }
  
  // Run app
  runApp(AlarmApp(alarmProvider: alarmProvider));
}

class AlarmApp extends StatelessWidget {
  final AlarmProvider alarmProvider;
  
  const AlarmApp({super.key, required this.alarmProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: alarmProvider),
        ChangeNotifierProvider(create: (context) => AppSettings()),
        ChangeNotifierProvider(create: (context) => BatteryService()),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Alarm',
            debugShowCheckedModeBanner: false,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4A90D9),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: const Color(0xFF4A90D9),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              switchTheme: SwitchThemeData(
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF4A90D9);
                  }
                  return Colors.white;
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF4A90D9).withOpacity(0.3);
                  }
                  return Colors.grey.shade300;
                }),
              ),
            ),
            darkTheme: ThemeData(
              textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4A90D9),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF121212),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF121212),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: const Color(0xFF7B68EE),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            home: const AlarmListScreen(),
            routes: {
              '/home': (context) => const AlarmListScreen(),
            },
          );
        },
      ),
    );
  }
}
