import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'services/timer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize services
  final settingsService = await SettingsService.getInstance();
  final timerService = TimerService.getInstance();
  await timerService.initialize();

  runApp(NapTapApp(settingsService: settingsService));
}

class NapTapApp extends StatelessWidget {
  final SettingsService settingsService;

  const NapTapApp({
    super.key,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: MaterialApp(
        title: 'NapTap',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: HomeScreen(settingsService: settingsService),
      ),
    );
  }
}
