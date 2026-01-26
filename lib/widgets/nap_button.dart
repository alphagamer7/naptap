import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class NapButton extends StatefulWidget {
  final int minutes;
  final VoidCallback onTap;

  const NapButton({
    super.key,
    required this.minutes,
    required this.onTap,
  });

  @override
  State<NapButton> createState() => _NapButtonState();
}

class _NapButtonState extends State<NapButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: AppTheme.buttonFeedback,
        height: AppTheme.buttonHeight,
        width: AppTheme.buttonWidth,
        decoration: BoxDecoration(
          color: _isPressed ? AppTheme.buttonPressed : AppTheme.buttonBackground,
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
          border: Border.all(
            color: AppTheme.buttonBorder,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            '${widget.minutes} min',
            style: AppTheme.buttonTextStyle.copyWith(
              color: _isPressed ? AppTheme.lightGrey : AppTheme.white,
            ),
          ),
        ),
      ),
    );
  }
}
