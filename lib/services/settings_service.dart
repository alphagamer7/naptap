import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _vibrationKey = 'vibration_enabled';
  static const String _soundKey = 'sound_enabled';
  static const String _defaultDurationKey = 'default_duration';

  static SettingsService? _instance;
  late SharedPreferences _prefs;

  SettingsService._();

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
  bool get vibrationEnabled => _prefs.getBool(_vibrationKey) ?? true;

  Future<void> setVibrationEnabled(bool value) async {
    await _prefs.setBool(_vibrationKey, value);
  }

  // Sound setting
  bool get soundEnabled => _prefs.getBool(_soundKey) ?? true;

  Future<void> setSoundEnabled(bool value) async {
    await _prefs.setBool(_soundKey, value);
  }

  // Default duration (in minutes)
  int get defaultDuration => _prefs.getInt(_defaultDurationKey) ?? 20;

  Future<void> setDefaultDuration(int minutes) async {
    await _prefs.setInt(_defaultDurationKey, minutes);
  }
}
