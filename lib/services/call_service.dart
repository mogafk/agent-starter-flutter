import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

/// Android foreground service (CallService.kt) that keeps the call running while the app is
/// in the background. No-op on other platforms.
class CallService {
  static const _channel = MethodChannel('englishmans/call_service');
  static final _logger = Logger('CallService');

  static bool get _isSupported => !kIsWeb && Platform.isAndroid;

  /// Starts the service, or refreshes it so it picks up newly granted mic/camera permissions.
  static Future<void> start({required String title}) async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod('start', {'title': title});
    } catch (error) {
      _logger.warning('Failed to start call service: $error');
    }
  }

  /// Sends the app to the background without finishing the activity (which would end the call).
  static Future<void> moveToBackground() async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod('moveToBackground');
    } catch (error) {
      _logger.warning('Failed to move app to background: $error');
    }
  }

  static Future<void> stop() async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod('stop');
    } catch (error) {
      _logger.warning('Failed to stop call service: $error');
    }
  }
}
