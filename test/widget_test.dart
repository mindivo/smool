import 'package:flutter_test/flutter_test.dart';

import 'package:smool/models/pinned_location.dart';
import 'package:smool/services/location_helper.dart';
import 'package:smool/services/maps_link_parser.dart';

void main() {
  test('PinnedLocation round-trips through JSON', () {
    final pin = const PinnedLocation(
      id: 'abc',
      name: 'Bedroom',
      latitude: 37.7749,
      longitude: -122.4194,
      radiusMeters: 50,
    );
    final encoded = PinnedLocation.encodeList([pin]);
    final decoded = PinnedLocation.decodeList(encoded);
    expect(decoded.length, 1);
    expect(decoded.first.id, pin.id);
    expect(decoded.first.name, pin.name);
    expect(decoded.first.radiusMeters, pin.radiusMeters);
  });

  test('Distance between identical points is zero', () {
    final d = LocationHelper.distanceMeters(0, 0, 0, 0);
    expect(d, 0.0);
  });

  test('Distance to ~1 degree latitude is ~111 km', () {
    final d = LocationHelper.distanceMeters(0, 0, 1, 0);
    expect(d, greaterThan(110_000));
    expect(d, lessThan(112_000));
  });

  group('MapsLinkParser', () {
    test('reads @lat,lon camera-center URLs', () async {
      const url =
          'https://www.google.com/maps/place/Eiffel+Tower/@48.8583701,2.2922873,17z';
      final result = await MapsLinkParser.parse(url);
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(48.8583701, 0.0001));
      expect(result.longitude, closeTo(2.2922873, 0.0001));
      expect(result.suggestedName, 'Eiffel Tower');
    });

    test('prefers !3d!4d place pin over @lat,lon camera', () async {
      const url =
          'https://www.google.com/maps/place/X/@48.8,2.3,17z/data=!3m1!4b1!4m6!3m5!1s0x47!8m2!3d40.7128!4d-74.0060!16s%2Fg%2F11';
      final result = await MapsLinkParser.parse(url);
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(40.7128, 0.0001));
      expect(result.longitude, closeTo(-74.0060, 0.0001));
    });

    test('reads ?q=lat,lon URLs', () async {
      const url = 'https://www.google.com/maps?q=37.7749,-122.4194';
      final result = await MapsLinkParser.parse(url);
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(37.7749, 0.0001));
      expect(result.longitude, closeTo(-122.4194, 0.0001));
    });

    test('reads ?query=lat,lon URLs', () async {
      const url =
          'https://www.google.com/maps/search/?api=1&query=51.5074,-0.1278';
      final result = await MapsLinkParser.parse(url);
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(51.5074, 0.0001));
    });

    test('extracts URL from surrounding shared text', () async {
      const text =
          'Check this out!\nhttps://www.google.com/maps?q=10.0,20.0\nLove it.';
      final result = await MapsLinkParser.parse(text);
      expect(result, isNotNull);
      expect(result!.latitude, 10.0);
      expect(result.longitude, 20.0);
    });

    test('returns null for non-maps text', () async {
      final result = await MapsLinkParser.parse('hello world');
      expect(result, isNull);
    });
  });
}
