import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenLockService {
  static const MethodChannel _channel = MethodChannel('com.naptap/screen_lock');

  static Future<void> startLockTask() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('startLockTask');
      } on PlatformException catch (e) {
        debugPrint('Failed to start lock task: ${e.message}');
      }
    }
    // iOS: Cannot programmatically lock - user must use Guided Access
  }

  static Future<void> stopLockTask() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('stopLockTask');
      } on PlatformException catch (e) {
        debugPrint('Failed to stop lock task: ${e.message}');
      }
    }
  }

  static Future<bool> isLocked() async {
    if (Platform.isAndroid) {
      try {
        return await _channel.invokeMethod('isLocked') ?? false;
      } on PlatformException {
        return false;
      }
    }
    return false;
  }
}
