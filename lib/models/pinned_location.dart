import 'dart:convert';

class PinnedLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool enabled;

  const PinnedLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 50.0,
    this.enabled = true,
  });

  PinnedLocation copyWith({
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    bool? enabled,
  }) {
    return PinnedLocation(
      id: id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'enabled': enabled,
      };

  factory PinnedLocation.fromJson(Map<String, dynamic> json) => PinnedLocation(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 50.0,
        enabled: (json['enabled'] as bool?) ?? true,
      );

  static String encodeList(List<PinnedLocation> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<PinnedLocation> decodeList(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => PinnedLocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
