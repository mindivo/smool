import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/pinned_location.dart';
import '../services/location_helper.dart';
import '../services/maps_link_parser.dart';
import '../services/pinned_locations_repo.dart';
import '../services/tracking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/glass.dart';

class AddLocationScreen extends StatefulWidget {
  final PinnedLocationsRepo repo;
  final TrackingService tracking;
  final LocationHelper locationHelper;

  const AddLocationScreen({
    super.key,
    required this.repo,
    required this.tracking,
    required this.locationHelper,
  });

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _nameCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  double _radius = 50;
  bool _busy = false;
  bool _resolvingLink = false;
  String? _linkError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pasteLink() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      setState(() => _linkError = 'Clipboard is empty.');
      return;
    }
    _linkCtrl.text = text;
    await _resolveLink(text);
  }

  Future<void> _resolveLink([String? raw]) async {
    final input = (raw ?? _linkCtrl.text).trim();
    if (input.isEmpty) {
      setState(() => _linkError = 'Paste a Google Maps link first.');
      return;
    }
    setState(() {
      _resolvingLink = true;
      _linkError = null;
    });
    final parsed = await MapsLinkParser.parse(input);
    if (!mounted) return;
    setState(() {
      _resolvingLink = false;
      if (parsed == null) {
        _linkError = "Couldn't read coordinates from that link.";
      } else {
        _latCtrl.text = parsed.latitude.toStringAsFixed(6);
        _lonCtrl.text = parsed.longitude.toStringAsFixed(6);
        if (_nameCtrl.text.trim().isEmpty &&
            parsed.suggestedName != null) {
          _nameCtrl.text = parsed.suggestedName!;
        }
      }
    });
  }

  Future<void> _useCurrent() async {
    setState(() => _busy = true);
    final p = await widget.locationHelper.currentPosition();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (p != null) {
        _latCtrl.text = p.latitude.toStringAsFixed(6);
        _lonCtrl.text = p.longitude.toStringAsFixed(6);
      }
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final lat = double.tryParse(_latCtrl.text.trim());
    final lon = double.tryParse(_lonCtrl.text.trim());
    if (name.isEmpty || lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a name and coordinates first.')),
      );
      return;
    }
    final pin = PinnedLocation(
      id: const Uuid().v4(),
      name: name,
      latitude: lat,
      longitude: lon,
      radiusMeters: _radius,
    );
    await widget.repo.add(pin);
    await widget.tracking.notifyPinnedLocationsChanged();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  _topBar(),
                  const SizedBox(height: 24),
                  GlassCard(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                    borderRadius: 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A new place to soften',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pin a location and set the quiet radius. When you arrive, the phone hushes.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        _label('Name'),
                        _textField(
                          _nameCtrl,
                          hint: 'Bedroom, Library, Studio…',
                        ),
                        const SizedBox(height: 18),
                        _label('Google Maps link'),
                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                _linkCtrl,
                                hint: 'https://maps.app.goo.gl/…',
                                keyboardType: TextInputType.url,
                                onSubmitted: (_) => _resolveLink(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GlassCircleIcon(
                              icon: _resolvingLink
                                  ? Icons.hourglass_empty_rounded
                                  : Icons.content_paste_rounded,
                              size: 48,
                              onTap: _resolvingLink ? null : _pasteLink,
                            ),
                          ],
                        ),
                        if (_linkError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 4),
                            child: Text(
                              _linkError!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.red.shade700),
                            ),
                          ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Latitude'),
                                  _textField(
                                    _latCtrl,
                                    hint: '37.7749',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                          signed: true,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Longitude'),
                                  _textField(
                                    _lonCtrl,
                                    hint: '-122.4194',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                          signed: true,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GlassPill(
                            onTap: _busy ? null : _useCurrent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _busy
                                      ? Icons.hourglass_empty_rounded
                                      : Icons.my_location_rounded,
                                  size: 18,
                                  color: SmoolColors.stone,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _busy
                                      ? 'Reading…'
                                      : 'Use my current location',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            _label('Quiet radius'),
                            const Spacer(),
                            Text(
                              '${_radius.toStringAsFixed(0)} m',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        Slider(
                          value: _radius,
                          min: 5,
                          max: 300,
                          divisions: 59,
                          activeColor: SmoolColors.accentCalm,
                          inactiveColor: SmoolColors.glassEdge,
                          onChanged: (v) => setState(() => _radius = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: GlassPill(
                  onTap: _save,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Save pin',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            ],
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
          Text('Pin a place', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          letterSpacing: 1.6,
          color: SmoolColors.stoneSoft,
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SmoolColors.glassEdge),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: SmoolColors.stone),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: SmoolColors.muted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
