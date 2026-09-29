import 'package:hive/hive.dart';

import '../ssdm_constants.dart';

part 'visit.g.dart';

/// Statut d'une visite.
enum VisitStatus {
  planned('Planifiée'),
  confirmed('Confirmée'),
  inProgress('En cours'),
  done('Terminée'),
  cancelled('Annulée'),
  postponed('Reportée');

  const VisitStatus(this.label);
  final String label;
}

/// Visite client.
///
/// Une visite peut être rattachée à :
/// - Un ou plusieurs IV ([ivIds])
/// - Une ligne du Sales Plan ([planEntryId])
/// - Une action ([actionId])
///
/// Les notes sont divisées en trois parties : avant, pendant, après le RDV.
@HiveType(typeId: 25)
class Visit extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int year;

  /// ID du client (référence vers shared_clients).
  @HiveField(2)
  String clientId;

  /// IDs des IV participants (référence vers shared_ivs).
  /// Peut contenir plusieurs IDs ou la sentinelle kAllId pour "Tous".
  @HiveField(3)
  List<String>? ivIds;

  /// IDs des lignes du Sales Plan (optionnel).
  /// Peut contenir plusieurs IDs pour une visite liée à plusieurs lignes.
  @HiveField(4)
  List<String>? planEntryIds;

  /// IDs des actions (optionnel).
  /// Peut contenir plusieurs IDs pour une visite liée à plusieurs actions.
  @HiveField(5)
  List<String>? actionIds;

  /// Titre ou objet de la visite.
  @HiveField(6)
  String title;

  /// Date et heure du rendez-vous.
  @HiveField(7)
  DateTime appointmentDate;

  /// Durée estimée en minutes.
  @HiveField(8)
  int estimatedDuration;

  /// Lieu du rendez-vous.
  @HiveField(9)
  String location;

  /// IDs des gammes de produits (référence vers shared_product_ranges).
  @HiveField(10)
  List<String>? productRangeIds;

  /// Chemins des documents joints (fichiers locaux).
  @HiveField(11)
  List<String>? documentPaths;

  /// Thèmes à aborder (liste de sujets) - obsolète, remplacé par productRangeIds.
  @HiveField(12)
  List<String> themes;

  /// Notes préparées avant le RDV.
  @HiveField(13)
  String notesBefore;

  /// Notes prises pendant le RDV.
  @HiveField(14)
  String notesDuring;

  /// Notes et suivi après le RDV.
  @HiveField(15)
  String notesAfter;

  /// Statut de la visite.
  @HiveField(16)
  int statusIndex;

  /// Date de création.
  @HiveField(17)
  DateTime createdAt;

  /// Date de dernière modification.
  @HiveField(18)
  DateTime updatedAt;

  /// ID de la trame de visite associée (optionnel).
  @HiveField(19)
  String? visitFrameId;

  Visit({
    required this.id,
    required this.year,
    required this.clientId,
    this.ivIds,
    this.planEntryIds,
    this.actionIds,
    this.productRangeIds,
    this.documentPaths,
    this.visitFrameId,
    this.title = '',
    required this.appointmentDate,
    this.estimatedDuration = 60,
    this.location = '',
    this.themes = const [],
    this.notesBefore = '',
    this.notesDuring = '',
    this.notesAfter = '',
    // 0 = VisitStatus.planned.index
    this.statusIndex = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  VisitStatus get status => VisitStatus.values[statusIndex];

  set status(VisitStatus value) => statusIndex = value.index;

  /// Vrai si la visite est une visite d'équipe (pas d'IV assigné).
  bool get isTeamVisit => ivIds == null || ivIds!.isEmpty;

  /// Vrai si la visite est assignée à tous les IV.
  bool get isAllIvs => ivIds != null && ivIds!.contains(kAllId);

  /// Vrai si la visite est terminée.
  bool get isCompleted => status == VisitStatus.done;

  /// Vrai si la visite est annulée ou reportée.
  bool get isCancelled =>
      status == VisitStatus.cancelled || status == VisitStatus.postponed;

  /// Premier ID de ligne du Sales Plan (pour compatibilité ascendante).
  /// Retourne null si aucun planEntryIds n'est défini.
  String? get planEntryId => planEntryIds?.isNotEmpty == true ? planEntryIds!.first : null;

  /// Premier ID d'action (pour compatibilité ascendante).
  /// Retourne null si aucun actionIds n'est défini.
  String? get actionId => actionIds?.isNotEmpty == true ? actionIds!.first : null;

  /// Vrai si la visite a des gammes de produits associées.
  bool get hasProductRanges => productRangeIds != null && productRangeIds!.isNotEmpty;

  /// Vrai si la visite a des documents joints.
  bool get hasDocuments => documentPaths != null && documentPaths!.isNotEmpty;

  /// Vrai si la visite a une trame associée.
  bool get hasVisitFrame => visitFrameId != null && visitFrameId!.isNotEmpty;

  /// Vrai si la visite est liée à au moins une ligne du Sales Plan.
  bool get hasPlanEntries => planEntryIds != null && planEntryIds!.isNotEmpty;

  /// Vrai si la visite est liée à au moins une action.
  bool get hasActions => actionIds != null && actionIds!.isNotEmpty;

  /// Vrai si la visite est en retard (date dépassée et pas terminée/annulée).
  bool get isLate =>
      appointmentDate.isBefore(DateTime.now()) &&
      status != VisitStatus.done &&
      status != VisitStatus.cancelled &&
      status != VisitStatus.postponed;
}
