/// Noms des boxes Hive.
///
/// Convention de nommage :
/// - les boxes préfixées `shared_` contiennent les données partagées entre
///   tous les modules (IV, groupes de clients, types de clients...). C'est
///   ce "socle commun" qui sera également utilise par les outils externes
///   (WUECT...) lorsqu'ils seront intégrés.
/// - chaque module possede ses propres boxes préfixées par son identifiant
///   (ex. `ssdm_` pour Service Sales Dev Management).
abstract final class BoxNames {
  // --- Boxes partagées (socle commun) ---
  static const ivs = 'shared_ivs';
  static const clientGroups = 'shared_client_groups';
  static const clientTypes = 'shared_client_types';
  static const clients = 'shared_clients';
  static const contacts = 'shared_contacts';
  static const productRanges = 'shared_product_ranges';

  // --- Module SSDM ---
  static const ssdmYears = 'ssdm_years';
  static const ssdmPlan = 'ssdm_plan';
  static const ssdmActions = 'ssdm_actions';
  static const ssdmVisits = 'ssdm_visits';
  static const ssdmVisitFrames = 'ssdm_visit_frames';

  // --- Module WUECT ---
  static const wuectProjets = 'wuect_projets';
  static const wuectSystemes = 'wuect_systemes';
  static const wuectPompes = 'wuect_pompes';
  static const wuectSettings = 'wuect_settings';

  static const all = [
    ivs,
    clientGroups,
    clientTypes,
    clients,
    contacts,
    productRanges,
    ssdmYears,
    ssdmPlan,
    ssdmActions,
    ssdmVisits,
    ssdmVisitFrames,
    wuectProjets,
    wuectSystemes,
    wuectPompes,
    wuectSettings,
  ];
}
