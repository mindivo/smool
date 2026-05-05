import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'screens/home_screen.dart';
import 'services/location_helper.dart';
import 'services/permissions_service.dart';
import 'services/pinned_locations_repo.dart';
import 'services/tracking_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize liquid_glass_widgets
  await LiquidGlassWidgets.initialize();

  final repo = PinnedLocationsRepo();
  await repo.load();

  runApp(LiquidGlassWidgets.wrap(
    SmoolApp(
      repo: repo,
      tracking: TrackingService(),
      permissions: PermissionsService(),
      locationHelper: LocationHelper(),
    ),
    adaptiveQuality: true,
  ));
}

class SmoolApp extends StatelessWidget {
  final PinnedLocationsRepo repo;
  final TrackingService tracking;
  final PermissionsService permissions;
  final LocationHelper locationHelper;

  const SmoolApp({
    super.key,
    required this.repo,
    required this.tracking,
    required this.permissions,
    required this.locationHelper,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smool',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: HomeScreen(
        repo: repo,
        tracking: tracking,
        permissions: permissions,
        locationHelper: locationHelper,
      ),
    );
  }
}
