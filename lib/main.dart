import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'services/timer_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  } catch (_) {}

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize services with error handling
  SettingsService? settingsService;
  try {
    settingsService = await SettingsService.getInstance();
  } catch (_) {
    settingsService = null;
  }

  try {
    final timerService = TimerService.getInstance();
    await timerService.initialize();
  } catch (_) {}

  // Initialize notification service for alarm sounds
  try {
    final notificationService = NotificationService.getInstance();
    await notificationService.initialize();
  } catch (_) {}

  runApp(NapTapApp(settingsService: settingsService));
}

class NapTapApp extends StatelessWidget {
  final SettingsService? settingsService;

  const NapTapApp({
    super.key,
    this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    // Create a default settings service if none provided
    final settings = settingsService ?? SettingsService.createDefault();

    return WithForegroundTask(
      child: MaterialApp(
        title: 'NapTap',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: HomeScreen(settingsService: settings),
      ),
    );
  }
}
