import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart';

class SettingsModal extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsModal({
    super.key,
    required this.settingsService,
  });

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  late bool _soundEnabled;
  late bool _vibrationEnabled;

  @override
  void initState() {
    super.initState();
    _soundEnabled = widget.settingsService.soundEnabled;
    _vibrationEnabled = widget.settingsService.vibrationEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.buttonBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Settings',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 24,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          _buildToggle(
            'Alarm Sound',
            _soundEnabled,
            (value) async {
              setState(() => _soundEnabled = value);
              await widget.settingsService.setSoundEnabled(value);
            },
          ),
          const SizedBox(height: 16),
          _buildToggle(
            'Vibration',
            _vibrationEnabled,
            (value) async {
              setState(() => _vibrationEnabled = value);
              await widget.settingsService.setVibrationEnabled(value);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildToggle(String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.white,
          activeTrackColor: AppTheme.grey,
          inactiveThumbColor: AppTheme.lightGrey,
          inactiveTrackColor: AppTheme.buttonBackground,
        ),
      ],
    );
  }
}
