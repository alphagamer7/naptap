import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AlarmService {
  static AlarmService? _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _volumeRampTimer;
  Timer? _vibrationTimer;
  Timer? _hapticTimer;
  bool _isPlaying = false;
  bool _audioAvailable = false;
  bool _sessionConfigured = false;

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

  /// Configure audio session to play even in silent mode on iOS
  Future<void> _configureAudioSession() async {
    if (_sessionConfigured) return;

    try {
      final session = await AudioSession.instance;

      if (Platform.isIOS) {
        // Configure for alarm-like playback that ignores silent mode
        await session.configure(const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        ));
      } else {
        // Android configuration
        await session.configure(const AudioSessionConfiguration(
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.sonification,
            usage: AndroidAudioUsage.alarm,
            flags: AndroidAudioFlags.audibilityEnforced,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: false,
        ));
      }

      await session.setActive(true);
      _sessionConfigured = true;
      debugPrint('AlarmService: Audio session configured for ${Platform.isIOS ? "iOS" : "Android"}');
    } catch (e) {
      debugPrint('AlarmService: Failed to configure audio session: $e');
    }
  }

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
      // Configure audio session FIRST (critical for iOS silent mode)
      await _configureAudioSession();

      // Try to load from assets first
      try {
        await _audioPlayer.setAsset('assets/sounds/alarm.mp3');
        _audioAvailable = true;
        debugPrint('AlarmService: Loaded alarm from assets');
      } catch (e) {
        debugPrint('AlarmService: Asset load failed: $e, trying URL fallback');
        // Fall back to URL-based sound
        try {
          await _audioPlayer.setUrl(_fallbackAlarmUrl);
          _audioAvailable = true;
          debugPrint('AlarmService: Loaded alarm from URL');
        } catch (e2) {
          debugPrint('AlarmService: URL load failed: $e2');
          _audioAvailable = false;
        }
      }

      if (!_audioAvailable) {
        debugPrint('AlarmService: No audio available, using haptic fallback');
        _startHapticLoop();
        return;
      }

      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.setVolume(_startVolume);
      debugPrint('AlarmService: Starting playback...');
      await _audioPlayer.play();
      debugPrint('AlarmService: Playback started');

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
      debugPrint('AlarmService: Audio playback error: $e');
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
