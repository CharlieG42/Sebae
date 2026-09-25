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

  // --- Module SSDM ---
  static const ssdmYears = 'ssdm_years';
  static const ssdmPlan = 'ssdm_plan';
  static const ssdmActions = 'ssdm_actions';

  static const all = [
    ivs,
    clientGroups,
    clientTypes,
    ssdmYears,
    ssdmPlan,
    ssdmActions,
  ];
}
