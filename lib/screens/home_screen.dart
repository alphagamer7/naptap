import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/nap_button.dart';
import '../widgets/settings_modal.dart';
import '../services/settings_service.dart';
import 'nap_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  final SettingsService settingsService;

  const HomeScreen({
    super.key,
    required this.settingsService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _customMinutes = 15;

  void _startNap(BuildContext context, int minutes) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => NapScreen(
          durationMinutes: minutes,
          settingsService: widget.settingsService,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: AppTheme.fadeTransition,
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsModal(settingsService: widget.settingsService),
    );
  }

  void _showCustomTimePicker(BuildContext context) {
    int tempMinutes = _customMinutes;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.buttonBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Custom Duration',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              // Wheel picker
              SizedBox(
                height: 180,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Minutes wheel
                    SizedBox(
                      width: 100,
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: tempMinutes - 1,
                        ),
                        itemExtent: 50,
                        selectionOverlay: Container(
                          decoration: BoxDecoration(
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: AppTheme.lightGrey.withAlpha(50),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        onSelectedItemChanged: (index) {
                          setModalState(() => tempMinutes = index + 1);
                        },
                        children: List.generate(120, (index) {
                          return Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'min',
                      style: TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _customMinutes = tempMinutes);
                    Navigator.pop(context);
                    _startNap(context, tempMinutes);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.white,
                    foregroundColor: AppTheme.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'START NAP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for black background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content - centered buttons
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App title
                  const Text(
                    'NAPTAP',
                    style: AppTheme.headingStyle,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Power nap in one tap',
                    style: AppTheme.subtitleStyle,
                  ),
                  const SizedBox(height: 60),

                  // Duration buttons
                  NapButton(
                    minutes: 10,
                    onTap: () => _startNap(context, 10),
                  ),
                  const SizedBox(height: 20),
                  NapButton(
                    minutes: 20,
                    onTap: () => _startNap(context, 20),
                  ),
                  const SizedBox(height: 20),
                  NapButton(
                    minutes: 30,
                    onTap: () => _startNap(context, 30),
                  ),
                  const SizedBox(height: 32),
                  // Custom time button
                  GestureDetector(
                    onTap: () => _showCustomTimePicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.lightGrey.withAlpha(100)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, color: AppTheme.lightGrey, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Custom time',
                            style: TextStyle(
                              color: AppTheme.lightGrey,
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Top right buttons - Stats and Settings
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StatsScreen()),
                      );
                    },
                    icon: const Icon(
                      Icons.bar_chart_outlined,
                      color: AppTheme.lightGrey,
                      size: AppTheme.iconSize,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showSettings(context),
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppTheme.lightGrey,
                      size: AppTheme.iconSize,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
