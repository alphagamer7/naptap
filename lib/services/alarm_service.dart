import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

class AlarmService {
  static AlarmService? _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _volumeRampTimer;
  Timer? _vibrationTimer;
  Timer? _hapticTimer;
  bool _isPlaying = false;
  bool _audioAvailable = false;

  // Volume ramp settings
  static const double _startVolume = 0.1; // 10%
  static const double _endVolume = 1.0;   // 100%
  static const int _rampDurationSeconds = 20;

  // Fallback alarm sound URL (gentle chime)
  static const String _fallbackAlarmUrl =
      'https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3';

  AlarmService._();

  static AlarmService getInstance() {
    _instance ??= AlarmService._();
    return _instance!;
  }

  bool get isPlaying => _isPlaying;

  Future<void> startAlarm({
    required bool playSound,
    required bool vibrate,
  }) async {
    if (_isPlaying) return;
    _isPlaying = true;

    if (playSound) {
      await _startAudioWithRamp();
    }

    if (vibrate) {
      _startVibration();
    }

    // If neither sound nor vibration, at least provide haptic feedback
    if (!playSound && !vibrate) {
      _startHapticLoop();
    }
  }

  Future<void> _startAudioWithRamp() async {
    try {
      // Try to load from assets first
      try {
        await _audioPlayer.setAsset('assets/sounds/alarm.mp3');
        _audioAvailable = true;
      } catch (_) {
        // Fall back to URL-based sound
        try {
          await _audioPlayer.setUrl(_fallbackAlarmUrl);
          _audioAvailable = true;
        } catch (_) {
          _audioAvailable = false;
        }
      }

      if (!_audioAvailable) {
        _startHapticLoop();
        return;
      }

      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.setVolume(_startVolume);
      await _audioPlayer.play();

      // Start volume ramp
      double currentVolume = _startVolume;
      final volumeIncrement = (_endVolume - _startVolume) / (_rampDurationSeconds * 10);

      _volumeRampTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (timer) {
          if (!_isPlaying || currentVolume >= _endVolume) {
            timer.cancel();
            return;
          }
          currentVolume += volumeIncrement;
          if (currentVolume > _endVolume) currentVolume = _endVolume;
          _audioPlayer.setVolume(currentVolume);
        },
      );
    } catch (e) {
      // Fallback: use haptic feedback loop
      _startHapticLoop();
    }
  }

  void _startHapticLoop() {
    _hapticTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) {
        if (_isPlaying) {
          HapticFeedback.heavyImpact();
        }
      },
    );
    HapticFeedback.heavyImpact();
  }

  void _startVibration() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    // Vibrate in a pattern: 500ms on, 1000ms off
    _vibrationTimer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) async {
        if (_isPlaying) {
          Vibration.vibrate(duration: 500);
        }
      },
    );

    // Initial vibration
    Vibration.vibrate(duration: 500);
  }

  Future<void> stopAlarm() async {
    _isPlaying = false;

    _volumeRampTimer?.cancel();
    _volumeRampTimer = null;

    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    _hapticTimer?.cancel();
    _hapticTimer = null;

    await _audioPlayer.stop();
    Vibration.cancel();
  }

  void dispose() {
    stopAlarm();
    _audioPlayer.dispose();
  }
}
