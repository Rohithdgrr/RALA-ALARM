import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tzcore;
import 'models/app_settings.dart';
import 'providers/alarm_provider.dart';
import 'screens/alarm_list_screen.dart';
import 'screens/splash_screen.dart';
import 'services/battery_service.dart';
import 'services/notification_service.dart';
import 'services/boot_receiver.dart';

// Global navigator key for navigation from notification service
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezones
  tz.initializeTimeZones();
  // Use local location from timezone package
  tzcore.setLocalLocation(tzcore.local);
  
  // Initialize notification service
  await NotificationService().initialize();
  
  // Initialize boot receiver for alarm rescheduling
  await BootReceiver.initialize();
  
  // Load and reschedule all alarms on app start
  final alarmProvider = AlarmProvider();
  await alarmProvider.loadAlarms();
  
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
            home: const SplashScreen(),
            routes: {
              '/home': (context) => const AlarmListScreen(),
            },
          );
        },
      ),
    );
  }
}
