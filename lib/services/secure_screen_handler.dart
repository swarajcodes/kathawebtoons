import 'package:flutter/services.dart';

class SecureScreenHandler {
  static const MethodChannel _channel = MethodChannel('secure_screen_channel');

  static Future<void> enableSecureScreen() async {
    try {
      await _channel.invokeMethod('enableSecureScreen');
    } on PlatformException catch (e) {
      print("Failed to enable secure screen: ${e.message}");
    }
  }

  static Future<void> disableSecureScreen() async {
    try {
      await _channel.invokeMethod('disableSecureScreen');
    } on PlatformException catch (e) {
      print("Failed to disable secure screen: ${e.message}");
    }
  }
}