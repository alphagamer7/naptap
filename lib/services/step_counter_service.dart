import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:flutter/foundation.dart';

class StepCounterService {
  static StepCounterService? _instance;

  StreamSubscription<StepCount>? _stepSubscription;
  int _initialSteps = 0;
  int _currentSteps = 0;
  bool _isTracking = false;

  final int requiredSteps;
  Function(int stepsWalked, int stepsRequired)? onStepUpdate;
  Function()? onGoalReached;

  StepCounterService._({this.requiredSteps = 10});

  static StepCounterService getInstance({int requiredSteps = 10}) {
    _instance ??= StepCounterService._(requiredSteps: requiredSteps);
    return _instance!;
  }

  int get stepsWalked => _currentSteps - _initialSteps;
  bool get isTracking => _isTracking;
  bool get goalReached => stepsWalked >= requiredSteps;

  Future<void> startTracking({
    Function(int stepsWalked, int stepsRequired)? onStepUpdate,
    Function()? onGoalReached,
  }) async {
    if (_isTracking) return;

    this.onStepUpdate = onStepUpdate;
    this.onGoalReached = onGoalReached;
    _isTracking = true;
    _initialSteps = 0;
    _currentSteps = 0;

    try {
      _stepSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
      );
    } catch (e) {
      debugPrint('StepCounter: Failed to start pedometer: $e');
      _isTracking = false;
    }
  }

  void _onStepCount(StepCount event) {
    if (_initialSteps == 0) {
      _initialSteps = event.steps;
    }
    _currentSteps = event.steps;

    final walked = stepsWalked;
    debugPrint('StepCounter: Steps walked: $walked / $requiredSteps');

    onStepUpdate?.call(walked, requiredSteps);

    if (walked >= requiredSteps) {
      onGoalReached?.call();
      stopTracking();
    }
  }

  void _onStepCountError(dynamic error) {
    debugPrint('StepCounter: Error: $error');
  }

  void stopTracking() {
    _stepSubscription?.cancel();
    _stepSubscription = null;
    _isTracking = false;
    _initialSteps = 0;
    _currentSteps = 0;
    onStepUpdate = null;
    onGoalReached = null;
  }

  void dispose() {
    stopTracking();
    _instance = null;
  }
}
