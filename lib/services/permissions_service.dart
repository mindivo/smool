import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  Future<bool> requestForegroundLocation() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<bool> requestBackgroundLocation() async {
    final status = await Permission.locationAlways.request();
    return status.isGranted;
  }

  Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }

  Future<PermissionsSnapshot> snapshot() async {
    final fine = await Permission.locationWhenInUse.status;
    final bg = await Permission.locationAlways.status;
    final notif = await Permission.notification.status;
    return PermissionsSnapshot(
      foregroundLocation: fine.isGranted,
      backgroundLocation: bg.isGranted,
      notifications: notif.isGranted || notif.isLimited,
    );
  }

  Future<void> openSettings() => openAppSettings();
}

class PermissionsSnapshot {
  final bool foregroundLocation;
  final bool backgroundLocation;
  final bool notifications;
  const PermissionsSnapshot({
    required this.foregroundLocation,
    required this.backgroundLocation,
    required this.notifications,
  });

  bool get allEssentialGranted =>
      foregroundLocation && backgroundLocation && notifications;
}
