import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerService {
  static TimerService? _instance;

  Timer? _uiTimer;
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

    // Listen for data from the foreground task isolate
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  void _onReceiveTaskData(Object data) {
    final message = data.toString();
    debugPrint('TimerService: Received from task: $message');

    if (message == 'complete') {
      debugPrint('TimerService: Timer complete from foreground task!');
      _isRunning = false;
      _remainingSeconds = 0;
      _uiTimer?.cancel();
      _uiTimer = null;

      final callback = _onComplete;
      if (callback != null) {
        debugPrint('TimerService: Executing onComplete callback');
        callback();
      }
    } else if (message.startsWith('tick:')) {
      final seconds = int.tryParse(message.substring(5)) ?? 0;
      _remainingSeconds = seconds;
      _onTick?.call(seconds);
    }
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

    // Save end time to SharedPreferences so the foreground task can read it
    final endTime = DateTime.now().add(Duration(minutes: durationMinutes));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('nap_end_time', endTime.millisecondsSinceEpoch);
    await prefs.setInt('nap_duration_seconds', durationMinutes * 60);

    // Start foreground service - the real timer runs in NapTaskHandler
    await FlutterForegroundTask.startService(
      notificationTitle: 'NapTap',
      notificationText: 'Nap in progress...',
      callback: _startCallback,
    );

    debugPrint('TimerService: Started timer for $durationMinutes minutes, end time: $endTime');
  }

  Future<void> stopTimer() async {
    _uiTimer?.cancel();
    _uiTimer = null;
    _isRunning = false;
    _remainingSeconds = 0;
    _onComplete = null;
    _onTick = null;

    // Clear saved end time
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('nap_end_time');
      await prefs.remove('nap_duration_seconds');
    } catch (_) {}

    await FlutterForegroundTask.stopService();
  }

  void dispose() {
    stopTimer();
  }
}

// Required callback for foreground service - runs in separate isolate
@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(NapTaskHandler());
}

class NapTaskHandler extends TaskHandler {
  int _endTimeMs = 0;
  bool _completed = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('NapTaskHandler: onStart called');

    // Read end time from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _endTimeMs = prefs.getInt('nap_end_time') ?? 0;
    _completed = false;

    debugPrint('NapTaskHandler: End time = ${DateTime.fromMillisecondsSinceEpoch(_endTimeMs)}');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_completed || _endTimeMs == 0) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final remainingMs = _endTimeMs - now;

    if (remainingMs <= 0) {
      // Timer complete!
      _completed = true;
      debugPrint('NapTaskHandler: Timer complete!');

      FlutterForegroundTask.updateService(
        notificationTitle: 'NapTap',
        notificationText: 'Wake up! Your nap is over.',
      );

      // Notify the main app
      FlutterForegroundTask.sendDataToMain('complete');
    } else {
      final remainingSeconds = (remainingMs / 1000).ceil();
      final minutes = remainingSeconds ~/ 60;
      final seconds = remainingSeconds % 60;

      FlutterForegroundTask.updateService(
        notificationTitle: 'NapTap',
        notificationText: '$minutes:${seconds.toString().padLeft(2, '0')} remaining',
      );

      // Send tick to main app for UI updates
      FlutterForegroundTask.sendDataToMain('tick:$remainingSeconds');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('NapTaskHandler: onDestroy called');
  }
}
