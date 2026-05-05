import 'dart:io' as io;

class MapsLink {
  final double latitude;
  final double longitude;
  final String? suggestedName;
  const MapsLink({
    required this.latitude,
    required this.longitude,
    this.suggestedName,
  });
}

class MapsLinkParser {
  static Future<MapsLink?> parse(String input) async {
    final url = _extractUrl(input);
    if (url == null) return null;
    final expanded = await _expand(url);
    return _parseUrl(expanded);
  }

  static String? _extractUrl(String text) {
    final match = RegExp(r'https?://\S+').firstMatch(text);
    return match?.group(0);
  }

  static bool _isShortLink(String url) {
    return url.contains('maps.app.goo.gl') ||
        url.contains('goo.gl/maps') ||
        url.contains('g.co/');
  }

  static Future<String> _expand(String url, {int hops = 0}) async {
    if (hops > 5) return url;
    if (!_isShortLink(url)) return url;
    final client = io.HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = false;
      final response = await request.close();
      await response.drain<void>();
      if (response.isRedirect) {
        final location = response.headers.value('location');
        if (location != null && location.isNotEmpty) {
          return _expand(location, hops: hops + 1);
        }
      }
      return url;
    } catch (_) {
      return url;
    } finally {
      client.close();
    }
  }

  static MapsLink? _parseUrl(String url) {
    // !3d<lat>!4d<lon> points to the actual place pin.
    final dataMatch =
        RegExp(r'!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)').firstMatch(url);
    // @<lat>,<lon> is the camera center, used as a fallback.
    final atMatch =
        RegExp(r'@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)').firstMatch(url);

    final name = _extractName(url);

    if (dataMatch != null) {
      return MapsLink(
        latitude: double.parse(dataMatch.group(1)!),
        longitude: double.parse(dataMatch.group(2)!),
        suggestedName: name,
      );
    }
    if (atMatch != null) {
      return MapsLink(
        latitude: double.parse(atMatch.group(1)!),
        longitude: double.parse(atMatch.group(2)!),
        suggestedName: name,
      );
    }

    final uri = Uri.tryParse(url);
    if (uri != null) {
      for (final key in const ['q', 'query', 'destination', 'll', 'center']) {
        final value = uri.queryParameters[key];
        if (value == null) continue;
        final coord = _parseLatLonPair(value);
        if (coord != null) {
          return MapsLink(
            latitude: coord.$1,
            longitude: coord.$2,
            suggestedName: name,
          );
        }
      }
    }
    return null;
  }

  static (double, double)? _parseLatLonPair(String raw) {
    final parts = raw.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lon = double.tryParse(parts[1].trim());
    if (lat == null || lon == null) return null;
    return (lat, lon);
  }

  static String? _extractName(String url) {
    final m = RegExp(r'/place/([^/?@]+)').firstMatch(url);
    if (m == null) return null;
    final raw = m.group(1)!;
    final decoded = Uri.decodeComponent(raw.replaceAll('+', ' '));
    if (decoded.isEmpty ||
        decoded.startsWith('place_id:') ||
        decoded.startsWith('data=')) {
      return null;
    }
    return decoded;
  }
}
