import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pinned_location.dart';

class PinnedLocationsRepo {
  static const _key = 'pinned_locations';

  final _controller = StreamController<List<PinnedLocation>>.broadcast();
  List<PinnedLocation> _cache = const [];

  Stream<List<PinnedLocation>> get stream => _controller.stream;
  List<PinnedLocation> get current => List.unmodifiable(_cache);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _cache = (raw == null || raw.isEmpty)
        ? const []
        : PinnedLocation.decodeList(raw);
    _controller.add(_cache);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, PinnedLocation.encodeList(_cache));
    _controller.add(List.unmodifiable(_cache));
  }

  Future<void> add(PinnedLocation pin) async {
    _cache = [..._cache, pin];
    await _persist();
  }

  Future<void> update(PinnedLocation pin) async {
    _cache = _cache.map((e) => e.id == pin.id ? pin : e).toList();
    await _persist();
  }

  Future<void> remove(String id) async {
    _cache = _cache.where((e) => e.id != id).toList();
    await _persist();
  }

  Future<void> toggle(String id, bool enabled) async {
    _cache = _cache
        .map((e) => e.id == id ? e.copyWith(enabled: enabled) : e)
        .toList();
    await _persist();
  }

  void dispose() => _controller.close();
}
