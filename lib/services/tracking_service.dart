import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';

class TrackingService {
  static const _channel = MethodChannel('com.smool.smool/tracking');
  static const _autostartKey = 'autostart_enabled';

  Future<bool> startTracking() async {
    return await _channel.invokeMethod<bool>('startTracking') ?? false;
  }

  Future<bool> stopTracking() async {
    return await _channel.invokeMethod<bool>('stopTracking') ?? false;
  }

  Future<bool> isTracking() async {
    return await _channel.invokeMethod<bool>('isTracking') ?? false;
  }

  Future<void> notifyPinnedLocationsChanged() async {
    await _channel.invokeMethod('refreshPinnedLocations');
  }

  Future<bool> hasDndPermission() async {
    return await _channel.invokeMethod<bool>('hasDndPermission') ?? false;
  }

  Future<void> openDndSettings() async {
    await _channel.invokeMethod('openDndSettings');
  }

  Future<void> openBatterySettings() async {
    await _channel.invokeMethod('openBatterySettings');
  }

  Future<bool> getAutostart() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autostartKey) ?? true;
  }

  Future<void> setAutostart(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autostartKey, value);
  }
}
