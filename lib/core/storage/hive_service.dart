import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/models/client_group.dart';
import '../../shared/models/client_type.dart';
import '../../shared/models/iv.dart';
import '../../modules/ssdm/models/action_update.dart';
import '../../modules/ssdm/models/sales_action.dart';
import '../../modules/ssdm/models/sales_plan_entry.dart';
import '../../modules/ssdm/models/ssdm_year.dart';
import 'box_names.dart';

/// Initialisation de Hive et ouverture de toutes les boxes.
///
/// Les boxes partagées (`shared_*`) sont ouvertes ici une seule fois :
/// tous les modules y accedent via `Hive.box(...)`.
class HiveService {
  static var _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();

    // --- Adapters : entites partagées ---
    Hive.registerAdapter(IvAdapter());
    Hive.registerAdapter(ClientGroupAdapter());
    Hive.registerAdapter(ClientTypeAdapter());

    // --- Adapters : module SSDM ---
    Hive.registerAdapter(SsdmYearAdapter());
    Hive.registerAdapter(SalesPlanEntryAdapter());
    Hive.registerAdapter(SalesActionAdapter());
    Hive.registerAdapter(ActionUpdateAdapter());

    // --- Ouverture des boxes ---
    await Future.wait([
      Hive.openBox<Iv>(BoxNames.ivs),
      Hive.openBox<ClientGroup>(BoxNames.clientGroups),
      Hive.openBox<ClientType>(BoxNames.clientTypes),
      Hive.openBox<SsdmYear>(BoxNames.ssdmYears),
      Hive.openBox<SalesPlanEntry>(BoxNames.ssdmPlan),
      Hive.openBox<SalesAction>(BoxNames.ssdmActions),
    ]);

    _initialized = true;
  }
}
