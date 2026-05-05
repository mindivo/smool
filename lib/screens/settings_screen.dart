import 'package:flutter/material.dart';

import '../models/pinned_location.dart';
import '../services/permissions_service.dart';
import '../services/pinned_locations_repo.dart';
import '../services/tracking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/glass.dart';

class SettingsScreen extends StatefulWidget {
  final PinnedLocationsRepo repo;
  final TrackingService tracking;
  final PermissionsService permissions;

  const SettingsScreen({
    super.key,
    required this.repo,
    required this.tracking,
    required this.permissions,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasDnd = false;
  bool _autostart = true;
  PermissionsSnapshot? _perms;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final dnd = await widget.tracking.hasDndPermission();
    final auto = await widget.tracking.getAutostart();
    final perms = await widget.permissions.snapshot();
    if (!mounted) return;
    setState(() {
      _hasDnd = dnd;
      _autostart = auto;
      _perms = perms;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<List<PinnedLocation>>(
            stream: widget.repo.stream,
            initialData: widget.repo.current,
            builder: (context, snapshot) {
              final pins = snapshot.data ?? const <PinnedLocation>[];
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
                children: [
                  _topBar(),
                  const SizedBox(height: 24),
                  _heading('Quiet permissions'),
                  const SizedBox(height: 12),
                  _permissionTile(
                    title: 'Do Not Disturb access',
                    subtitle: _hasDnd
                        ? 'Granted · the phone can be auto-muted'
                        : 'Required to change the ringer mode',
                    granted: _hasDnd,
                    onTap: () async {
                      await widget.tracking.openDndSettings();
                      await Future.delayed(const Duration(seconds: 1));
                      await _refresh();
                    },
                  ),
                  _permissionTile(
                    title: 'Background location',
                    subtitle: (_perms?.backgroundLocation ?? false)
                        ? 'Granted · tracking continues when the app is closed'
                        : 'Required so the app can sense your zones',
                    granted: _perms?.backgroundLocation ?? false,
                    onTap: () async {
                      await widget.permissions.requestBackgroundLocation();
                      await _refresh();
                    },
                  ),
                  _permissionTile(
                    title: 'Notifications',
                    subtitle: (_perms?.notifications ?? false)
                        ? 'Granted'
                        : 'Required for the always-on tracking notice',
                    granted: _perms?.notifications ?? false,
                    onTap: () async {
                      await widget.permissions.requestNotifications();
                      await _refresh();
                    },
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.power_rounded,
                          color: SmoolColors.stoneSoft,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auto-start at boot',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Resume tracking when the phone restarts',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _autostart,
                          activeThumbColor: SmoolColors.accentCalm,
                          onChanged: (v) async {
                            await widget.tracking.setAutostart(v);
                            if (mounted) setState(() => _autostart = v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GlassPill(
                    onTap: () => widget.tracking.openBatterySettings(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.battery_saver_rounded,
                          color: SmoolColors.stone,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Battery optimization',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _heading('Pinned places'),
                  const SizedBox(height: 12),
                  if (pins.isEmpty)
                    GlassCard(
                      child: Text(
                        'You haven\'t pinned a place yet. Tap the plus on the home dock to add one.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ...pins.map(_pinTile),
                ],
              );
            },
          ),
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
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text, style: Theme.of(context).textTheme.headlineMedium),
    );
  }

  Widget _permissionTile({
    required String title,
    required String subtitle,
    required bool granted,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              granted
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: granted ? SmoolColors.accentCalm : SmoolColors.stoneSoft,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              granted ? Icons.lock_open_rounded : Icons.chevron_right_rounded,
              color: SmoolColors.stoneSoft,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pinTile(PinnedLocation pin) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: pin.enabled ? SmoolColors.accentCalm : SmoolColors.muted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pin.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${pin.latitude.toStringAsFixed(4)}, ${pin.longitude.toStringAsFixed(4)} · ${pin.radiusMeters.toStringAsFixed(0)}m',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Switch(
              value: pin.enabled,
              activeThumbColor: SmoolColors.accentCalm,
              onChanged: (v) async {
                await widget.repo.toggle(pin.id, v);
                await widget.tracking.notifyPinnedLocationsChanged();
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: SmoolColors.stoneSoft,
              ),
              onPressed: () async {
                await widget.repo.remove(pin.id);
                await widget.tracking.notifyPinnedLocationsChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
