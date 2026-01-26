import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF333333);
  static const Color lightGrey = Color(0xFF666666);

  // Button Colors
  static const Color buttonBackground = Color(0xFF1A1A1A);
  static const Color buttonBorder = Color(0xFF333333);
  static const Color buttonPressed = Color(0xFF2A2A2A);

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    color: white,
    fontSize: 32,
    fontWeight: FontWeight.w300,
    letterSpacing: 2,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: white,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 1,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: lightGrey,
    fontSize: 14,
    fontWeight: FontWeight.w300,
    letterSpacing: 0.5,
  );

  // Theme Data
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: black,
        primaryColor: white,
        colorScheme: const ColorScheme.dark(
          primary: white,
          secondary: grey,
          surface: black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: black,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: black,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        ),
        iconTheme: const IconThemeData(
          color: white,
          size: 24,
        ),
        textTheme: const TextTheme(
          headlineLarge: headingStyle,
          bodyLarge: buttonTextStyle,
          bodySmall: subtitleStyle,
        ),
      );

  // Animation Durations
  static const Duration fadeTransition = Duration(milliseconds: 300);
  static const Duration buttonFeedback = Duration(milliseconds: 100);

  // Sizes
  static const double buttonHeight = 80;
  static const double buttonWidth = 200;
  static const double buttonRadius = 40;
  static const double iconSize = 28;
}
