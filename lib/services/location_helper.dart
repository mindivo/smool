import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../models/pinned_location.dart';

class LocationHelper {
  Future<Position?> currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  Stream<Position> stream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    );
  }

  static double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;

  static ({PinnedLocation pin, double distance})? nearest(
    List<PinnedLocation> pins,
    double lat,
    double lon,
  ) {
    if (pins.isEmpty) return null;
    PinnedLocation? best;
    double bestDist = double.infinity;
    for (final p in pins) {
      final d = distanceMeters(lat, lon, p.latitude, p.longitude);
      if (d < bestDist) {
        bestDist = d;
        best = p;
      }
    }
    return best == null ? null : (pin: best, distance: bestDist);
  }
}
