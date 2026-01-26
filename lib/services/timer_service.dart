import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class TimerService {
  static TimerService? _instance;

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  Function()? _onComplete;
  Function(int)? _onTick;

  TimerService._();

  static TimerService getInstance() {
    _instance ??= TimerService._();
    return _instance!;
  }

  bool get isRunning => _isRunning;
  int get remainingSeconds => _remainingSeconds;

  Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'naptap_timer',
        channelName: 'NapTap Timer',
        channelDescription: 'Timer running for your power nap',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        visibility: NotificationVisibility.VISIBILITY_SECRET,
        playSound: false,
        enableVibration: false,
        showWhen: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  Future<void> startTimer({
    required int durationMinutes,
    required Function() onComplete,
    Function(int)? onTick,
  }) async {
    if (_isRunning) return;

    _remainingSeconds = durationMinutes * 60;
    _onComplete = onComplete;
    _onTick = onTick;
    _isRunning = true;

    // Start foreground service
    await _startForegroundService();

    // Start countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _onTick?.call(_remainingSeconds);
        _updateNotification();
        debugPrint('TimerService: $_remainingSeconds seconds remaining');
      } else {
        debugPrint('TimerService: Timer complete! Calling onComplete...');
        timer.cancel();
        _timer = null;
        _isRunning = false;

        // Call completion callback BEFORE stopping service
        final callback = _onComplete;
        if (callback != null) {
          debugPrint('TimerService: Executing onComplete callback');
          callback();
        } else {
          debugPrint('TimerService: WARNING - onComplete callback is null!');
        }

        // Stop foreground service after callback
        await FlutterForegroundTask.stopService();
        debugPrint('TimerService: Foreground service stopped');
      }
    });
  }

  Future<void> _startForegroundService() async {
    await FlutterForegroundTask.startService(
      notificationTitle: 'NapTap',
      notificationText: 'Nap in progress...',
      callback: _startCallback,
    );
  }

  void _updateNotification() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    FlutterForegroundTask.updateService(
      notificationTitle: 'NapTap',
      notificationText: '$minutes:${seconds.toString().padLeft(2, '0')} remaining',
    );
  }

  Future<void> stopTimer() async {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _remainingSeconds = 0;

    await FlutterForegroundTask.stopService();
  }

  void dispose() {
    stopTimer();
  }
}

// Required callback for foreground service
@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(NapTaskHandler());
}

class NapTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}
