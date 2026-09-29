import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../shared/models/client.dart';
import '../../shared/models/client_group.dart';
import '../../shared/models/client_type.dart';
import '../../shared/models/contact.dart';
import '../../shared/models/iv.dart';
import '../../shared/models/product_range.dart';
import '../../modules/ssdm/models/action_step.dart';
import '../../modules/ssdm/models/action_update.dart';
import '../../modules/ssdm/models/sales_action.dart';
import '../../modules/ssdm/models/sales_plan_entry.dart';
import '../../modules/ssdm/models/ssdm_year.dart';
import '../../modules/ssdm/models/visit.dart';
import '../../modules/ssdm/models/visit_frame.dart';
import 'box_names.dart';

/// Initialisation de Hive et ouverture de toutes les boxes.
///
/// Les boxes partagées (`shared_*`) sont ouvertes ici une seule fois :
/// tous les modules y accedent via `Hive.box(...)`.
class HiveService {
  static var _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    
    // Utiliser un répertoire local hors OneDrive pour éviter les problèmes de lock
    final appDir = await getApplicationSupportDirectory();
    final hivePath = path.join(appDir.path, 'hive_data');
    await Hive.initFlutter(hivePath);

    // --- Adapters : entites partagées ---
    Hive.registerAdapter(IvAdapter());
    Hive.registerAdapter(ClientGroupAdapter());
    Hive.registerAdapter(ClientTypeAdapter());
    // Nouveaux modèles partagés
    Hive.registerAdapter(ClientAdapter());
    Hive.registerAdapter(ContactAdapter());
    Hive.registerAdapter(ProductRangeAdapter());

    // --- Adapters : module SSDM ---
    Hive.registerAdapter(SsdmYearAdapter());
    Hive.registerAdapter(SalesPlanEntryAdapter());
    Hive.registerAdapter(SalesActionAdapter());
    Hive.registerAdapter(ActionUpdateAdapter());
    Hive.registerAdapter(ActionStepAdapter());
    // Nouveau modèle SSDM
    Hive.registerAdapter(VisitAdapter());
    // Modèle Trames de Visite
    Hive.registerAdapter(VisitFrameAdapter());

    // --- Ouverture des boxes ---
    await Future.wait([
      Hive.openBox<Iv>(BoxNames.ivs),
      Hive.openBox<ClientGroup>(BoxNames.clientGroups),
      Hive.openBox<ClientType>(BoxNames.clientTypes),
      // Nouvelles boxes partagées
      Hive.openBox<Client>(BoxNames.clients),
      Hive.openBox<Contact>(BoxNames.contacts),
      Hive.openBox<ProductRange>(BoxNames.productRanges),
      // Boxes SSDM existantes
      Hive.openBox<SsdmYear>(BoxNames.ssdmYears),
      Hive.openBox<SalesPlanEntry>(BoxNames.ssdmPlan),
      Hive.openBox<SalesAction>(BoxNames.ssdmActions),
      // Nouvelle box SSDM
      Hive.openBox<Visit>(BoxNames.ssdmVisits),
      // Box Trames de Visite
      Hive.openBox<VisitFrame>(BoxNames.ssdmVisitFrames),
    ]);

    _initialized = true;
  }
}
