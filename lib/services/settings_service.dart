import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _vibrationKey = 'vibration_enabled';
  static const String _soundKey = 'sound_enabled';
  static const String _defaultDurationKey = 'default_duration';

  static SettingsService? _instance;
  SharedPreferences? _prefs;
  bool _useDefaults = false;

  SettingsService._();

  // Create a default instance that uses hardcoded defaults (fallback)
  factory SettingsService.createDefault() {
    final service = SettingsService._();
    service._useDefaults = true;
    return service;
  }

  static Future<SettingsService> getInstance() async {
    if (_instance == null) {
      _instance = SettingsService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Vibration setting
  bool get vibrationEnabled {
    if (_useDefaults || _prefs == null) return true;
    return _prefs!.getBool(_vibrationKey) ?? true;
  }

  Future<void> setVibrationEnabled(bool value) async {
    await _prefs?.setBool(_vibrationKey, value);
  }

  // Sound setting
  bool get soundEnabled {
    if (_useDefaults || _prefs == null) return true;
    return _prefs!.getBool(_soundKey) ?? true;
  }

  Future<void> setSoundEnabled(bool value) async {
    await _prefs?.setBool(_soundKey, value);
  }

  // Default duration (in minutes)
  int get defaultDuration {
    if (_useDefaults || _prefs == null) return 20;
    return _prefs!.getInt(_defaultDurationKey) ?? 20;
  }

  Future<void> setDefaultDuration(int minutes) async {
    await _prefs?.setInt(_defaultDurationKey, minutes);
  }
}
