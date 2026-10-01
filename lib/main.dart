import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/storage/hive_service.dart';
import 'modules/ssdm/services/ssdm_service.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  // Initialise window_manager et attend que la fenetre soit prete
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow();

  // Configure la fenetre : maximisee (barre des taches visible, boutons de fenetre actifs)
  await windowManager.maximize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SsdmService()),
      ],
      child: const SebaeApp(),
    ),
  );
}
