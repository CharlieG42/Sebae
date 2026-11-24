import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/storage/hive_service.dart';
import 'modules/assessment/assessment_module.dart';
import 'modules/ssdm/services/ssdm_service.dart';
import 'modules/technical_products/services/technical_product_service.dart';
import 'modules/wuect/services/wuect_legacy_migration.dart';
import 'modules/wuect/services/wuect_migration_writer.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await HiveService.autoBackupOnLaunch();

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

  // Initialise les données de locale françaises
  await initializeDateFormatting('fr_FR');

  // Services du module Assessment IV : structure (thématiques / questions)
  // et réponses des utilisateurs. Initialisés avant runApp pour que les
  // vues du module disposent des données dès leur ouverture.
  final assessmentStructureService =
      AssessmentModule.createStructureService();
  await assessmentStructureService.init();
  final assessmentUserService =
      AssessmentModule.createAssessmentService(assessmentStructureService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SsdmService()),
        ChangeNotifierProvider(create: (_) => TechnicalProductService()),
        ChangeNotifierProvider.value(value: assessmentStructureService),
        ChangeNotifierProvider.value(value: assessmentUserService),
      ],
      child: const SebaeApp(),
    ),
  );
}
