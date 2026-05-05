import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/pinned_location.dart';
import '../services/location_helper.dart';
import '../services/permissions_service.dart';
import '../services/pinned_locations_repo.dart';
import '../services/tracking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/glass.dart';
import 'add_location_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final PinnedLocationsRepo repo;
  final TrackingService tracking;
  final PermissionsService permissions;
  final LocationHelper locationHelper;

  const HomeScreen({
    super.key,
    required this.repo,
    required this.tracking,
    required this.permissions,
    required this.locationHelper,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _position;
  StreamSubscription<Position>? _posSub;
  bool _trackingActive = false;
  bool _hasDnd = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final perms = await widget.permissions.snapshot();
    if (!perms.foregroundLocation) {
      await widget.permissions.requestForegroundLocation();
    }
    final dnd = await widget.tracking.hasDndPermission();
    final running = await widget.tracking.isTracking();
    if (!mounted) return;
    setState(() {
      _hasDnd = dnd;
      _trackingActive = running;
    });
    _listenLocation();
  }

  void _listenLocation() {
    _posSub?.cancel();
    _posSub = widget.locationHelper.stream().listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
  }

  Future<void> _toggleTracking() async {
    if (_trackingActive) {
      await widget.tracking.stopTracking();
    } else {
      await widget.permissions.requestForegroundLocation();
      await widget.permissions.requestBackgroundLocation();
      await widget.permissions.requestNotifications();
      if (!_hasDnd) {
        await widget.tracking.openDndSettings();
      }
      await widget.tracking.startTracking();
    }
    final running = await widget.tracking.isTracking();
    final dnd = await widget.tracking.hasDndPermission();
    if (!mounted) return;
    setState(() {
      _trackingActive = running;
      _hasDnd = dnd;
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: StreamBuilder<List<PinnedLocation>>(
          stream: widget.repo.stream,
          initialData: widget.repo.current,
          builder: (context, snapshot) {
            final pins = snapshot.data ?? const <PinnedLocation>[];
            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                  children: [
                    _topBar(),
                    const SizedBox(height: 24),
                    _statusHero(pins),
                    const SizedBox(height: 18),
                    _nearestCard(pins),
                    const SizedBox(height: 18),
                    _pinList(pins),
                  ],
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: _liquidDock(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          GlassCircleIcon(
            icon: Icons.menu_rounded,
            onTap: () => _openSettings(),
          ),
          const Spacer(),
          Text('Smool', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          GlassCircleIcon(
            icon: _trackingActive
                ? Icons.graphic_eq_rounded
                : Icons.power_settings_new_rounded,
            onTap: _toggleTracking,
          ),
        ],
      ),
    );
  }

  Widget _statusHero(List<PinnedLocation> pins) {
    final inside = _insideZone(pins);
    final title = inside != null
        ? '"You\'ve arrived in ${inside.name}.\nThe world is hushed."'
        : (_trackingActive
            ? '"A quiet readiness, watching for the places you\'ve named."'
            : '"Pause. Pin a place. Let it learn your stillness."');

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      borderRadius: 28,
      thickness: 27,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: SmoolColors.stone,
                ),
          ),
          const SizedBox(height: 18),
          _statusRow(pins, inside),
        ],
      ),
    );
  }

  Widget _statusRow(List<PinnedLocation> pins, PinnedLocation? inside) {
    final dotColor = inside != null
        ? SmoolColors.accentCalm
        : (_trackingActive ? SmoolColors.meadow : SmoolColors.muted);
    final label = inside != null
        ? 'Auto-muted'
        : (_trackingActive
            ? 'Watching · ${pins.where((p) => p.enabled).length} pins'
            : 'Paused');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  PinnedLocation? _insideZone(List<PinnedLocation> pins) {
    final p = _position;
    if (p == null) return null;
    for (final pin in pins.where((e) => e.enabled)) {
      final d = LocationHelper.distanceMeters(
          p.latitude, p.longitude, pin.latitude, pin.longitude);
      if (d <= pin.radiusMeters) return pin;
    }
    return null;
  }

  Widget _nearestCard(List<PinnedLocation> pins) {
    final activePins = pins.where((p) => p.enabled).toList();
    final p = _position;
    if (p == null || activePins.isEmpty) {
      return GlassCard(
        child: Row(
          children: [
            const GlassCircleIcon(icon: Icons.my_location_rounded, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                p == null
                    ? 'Locating you…'
                    : 'No active places. Enable a location to begin.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      );
    }
    final nearest =
        LocationHelper.nearest(activePins, p.latitude, p.longitude);
    if (nearest == null) return const SizedBox.shrink();

    final inside = nearest.distance <= nearest.pin.radiusMeters;
    final distanceText = inside
        ? '${nearest.distance.toStringAsFixed(1)} m from center'
        : '${nearest.distance.toStringAsFixed(0)} m away';
    return GlassCard(
      child: Row(
        children: [
          GlassCircleIcon(
            icon: inside ? Icons.volume_off_rounded : Icons.location_on_rounded,
            size: 44,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nearest pin',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(letterSpacing: 1.4)),
                const SizedBox(height: 4),
                Text(nearest.pin.name,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  distanceText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (inside) ...[
                  const SizedBox(height: 10),
                  _ZoneProgress(
                    distance: nearest.distance,
                    radius: nearest.pin.radiusMeters,
                  ),
                ],
              ],
            ),
          ),
          if (p.accuracy.isFinite)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '±${p.accuracy.toStringAsFixed(0)}m',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _pinList(List<PinnedLocation> pins) {
    if (pins.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
          child: Text('Pinned places',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        ...pins.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: p.enabled ? 1.0 : 0.4,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  onTap: () => _openSettings(),
                  thickness: 37,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: p.enabled
                              ? SmoolColors.accentCalm
                              : SmoolColors.muted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              '${p.radiusMeters.toStringAsFixed(0)}m radius',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        p.enabled
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        color: SmoolColors.stoneSoft,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _liquidDock() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: GlassCard(
        thickness: 37,
        borderRadius: 41,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _dockButton(Icons.spa_rounded, 'Home', () {}),
              _dockButton(Icons.add_rounded, 'Add', _addLocation),
              _dockButton(Icons.tune_rounded, 'Settings', _openSettings),
              _dockButton(
                _trackingActive
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                _trackingActive ? 'Pause' : 'Start',
                _toggleTracking,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dockButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Icon(icon, color: SmoolColors.stone, size: 26),
      ),
    );
  }

  Future<void> _addLocation() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddLocationScreen(
          repo: widget.repo,
          tracking: widget.tracking,
          locationHelper: widget.locationHelper,
        ),
      ),
    );
    if (added == true && mounted) {
      await widget.tracking.notifyPinnedLocationsChanged();
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          repo: widget.repo,
          tracking: widget.tracking,
          permissions: widget.permissions,
        ),
      ),
    );
    await widget.tracking.notifyPinnedLocationsChanged();
  }
}

class _ZoneProgress extends StatelessWidget {
  final double distance;
  final double radius;
  const _ZoneProgress({required this.distance, required this.radius});

  @override
  Widget build(BuildContext context) {
    final clamped = distance.clamp(0.0, radius);
    final fill = radius == 0 ? 0.0 : clamped / radius;
    final remaining = (radius - distance).clamp(0.0, radius);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(
                height: 6,
                color: SmoolColors.glassEdge,
              ),
              FractionallySizedBox(
                widthFactor: fill,
                child: Container(
                  height: 6,
                  color: SmoolColors.accentCalm,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${remaining.toStringAsFixed(1)} m to edge · ${radius.toStringAsFixed(0)} m zone',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
