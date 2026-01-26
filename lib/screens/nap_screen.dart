import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../theme/app_theme.dart';
import '../services/timer_service.dart';
import '../services/alarm_service.dart';
import '../services/settings_service.dart';
import '../services/screen_lock_service.dart';
import '../services/database_service.dart';
import '../services/step_counter_service.dart';
import '../services/notification_service.dart';

class NapScreen extends StatefulWidget {
  final int durationMinutes;
  final SettingsService settingsService;

  const NapScreen({
    super.key,
    required this.durationMinutes,
    required this.settingsService,
  });

  @override
  State<NapScreen> createState() => _NapScreenState();
}

class _NapScreenState extends State<NapScreen> with WidgetsBindingObserver {
  final TimerService _timerService = TimerService.getInstance();
  final AlarmService _alarmService = AlarmService.getInstance();
  final DatabaseService _dbService = DatabaseService.getInstance();
  final NotificationService _notificationService = NotificationService.getInstance();
  late final StepCounterService _stepService;

  bool _isAlarmRinging = false;
  bool _showTapHint = false;
  int _remainingSeconds = 0;
  bool _showTime = false;
  DateTime? _napStartTime;
  int _stepsWalked = 0;
  static const int _requiredSteps = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remainingSeconds = widget.durationMinutes * 60;
    _napStartTime = DateTime.now();
    _stepService = StepCounterService.getInstance(requiredSteps: _requiredSteps);
    _startNap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app goes to background and comes back, re-enable immersive mode
    if (state == AppLifecycleState.resumed && !_isAlarmRinging) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  Future<void> _startNap() async {
    // Keep screen on during entire nap (lock mode)
    await WakelockPlus.enable();

    // Set to immersive sticky mode - hides all system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Start screen pinning on Android (locks user into app)
    await ScreenLockService.startLockTask();

    await _timerService.startTimer(
      durationMinutes: widget.durationMinutes,
      onComplete: _onNapComplete,
      onTick: _onTick,
    );
  }

  void _onTick(int remainingSeconds) {
    if (mounted) {
      setState(() {
        _remainingSeconds = remainingSeconds;
      });
    }
  }

  void _onNapComplete() async {
    debugPrint('NapScreen: _onNapComplete called!');

    // Stop screen pinning when alarm rings so user can dismiss
    await ScreenLockService.stopLockTask();

    // Save nap record to database
    if (_napStartTime != null) {
      await _dbService.insertNapRecord(NapRecord(
        startTime: _napStartTime!,
        durationMinutes: widget.durationMinutes,
        completed: true,
      ));
    }

    debugPrint('NapScreen: Setting _isAlarmRinging = true');
    setState(() {
      _isAlarmRinging = true;
      _showTapHint = true;
      _showTime = false;
      _stepsWalked = 0;
    });
    debugPrint('NapScreen: setState complete, _isAlarmRinging = $_isAlarmRinging');

    // Start step tracking for walk-to-dismiss
    debugPrint('NapScreen: Starting step tracking...');
    await _stepService.startTracking(
      onStepUpdate: (steps, required) {
        if (mounted) {
          setState(() => _stepsWalked = steps);
        }
      },
      onGoalReached: () {
        if (mounted) {
          _stopAlarmAndReturn();
        }
      },
    );

    // Show notification with sound (works in silent mode on iOS)
    debugPrint('NapScreen: Showing alarm notification...');
    await _notificationService.showAlarmNotification();

    // Also start the in-app alarm
    debugPrint('NapScreen: Starting in-app alarm...');
    await _alarmService.startAlarm(
      playSound: widget.settingsService.soundEnabled,
      vibrate: widget.settingsService.vibrationEnabled,
    );
    debugPrint('NapScreen: Alarm started');
  }

  void _onScreenTap() {
    if (_isAlarmRinging) {
      // Only allow dismiss if walked enough steps
      if (_stepsWalked >= _requiredSteps) {
        _stopAlarmAndReturn();
      }
      // Otherwise ignore tap - must walk to dismiss
    } else {
      // During nap, briefly show time on tap
      setState(() {
        _showTime = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isAlarmRinging) {
          setState(() {
            _showTime = false;
          });
        }
      });
    }
  }

  Future<void> _stopAlarmAndReturn() async {
    _stepService.stopTracking();
    await _alarmService.stopAlarm();
    await _notificationService.cancelAlarmNotification();
    await ScreenLockService.stopLockTask();
    await WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerService.stopTimer();
    _alarmService.stopAlarm();
    _stepService.stopTracking();
    ScreenLockService.stopLockTask();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Only allow exit when alarm is ringing
        if (_isAlarmRinging) {
          await _stopAlarmAndReturn();
        }
        // During nap, back button does nothing (locked)
      },
      child: GestureDetector(
        onTap: _onScreenTap,
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          backgroundColor: AppTheme.black,
          body: Stack(
            children: [
              // Pure black background (covers entire screen)
              Container(color: AppTheme.black),

              // Time display (only shown on tap during nap)
              if (!_isAlarmRinging)
                Center(
                  child: AnimatedOpacity(
                    opacity: _showTime ? 0.3 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(_remainingSeconds),
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 64,
                            fontWeight: FontWeight.w200,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'remaining',
                          style: TextStyle(
                            color: AppTheme.lightGrey.withAlpha(100),
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        if (Platform.isIOS) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Enable Guided Access for full lock',
                            style: TextStyle(
                              color: AppTheme.lightGrey.withAlpha(80),
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Alarm ringing state - shows WAKE UP screen with step counter
              if (_isAlarmRinging)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.alarm,
                        color: AppTheme.white.withAlpha(200),
                        size: 64,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'WAKE UP',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Step counter progress
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_walk,
                            color: AppTheme.lightGrey.withAlpha(180),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$_stepsWalked / $_requiredSteps',
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'steps',
                            style: TextStyle(
                              color: AppTheme.lightGrey.withAlpha(180),
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Progress bar
                      Container(
                        width: 220,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.grey,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 220 * (_stepsWalked / _requiredSteps).clamp(0.0, 1.0),
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _stepsWalked >= _requiredSteps
                            ? 'Tap anywhere to dismiss'
                            : 'Walk ${_requiredSteps - _stepsWalked} more steps to dismiss',
                        style: TextStyle(
                          color: AppTheme.lightGrey.withAlpha(200),
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),

              // Lock indicator (subtle, at bottom)
              if (!_isAlarmRinging)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _showTime ? 0.2 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppTheme.lightGrey,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
