import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/storage/hive_service.dart';
import 'modules/ssdm/services/ssdm_service.dart';
import 'modules/wuect/services/wuect_legacy_migration.dart';
import 'modules/wuect/services/wuect_migration_writer.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  // Migration des données WUECT standalone (ancien dossier de données)
  // vers les boxes de Sebae. Exécutée une seule fois, non bloquante.
  await WuectLegacyMigration.runIfNeeded(
    writeEntities: WuectMigrationWriter.writeEntities,
  );

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
