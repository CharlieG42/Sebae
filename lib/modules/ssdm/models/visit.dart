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

enum FollowUpTaskStatus {
  waiting('En attente'),
  inProgress('En cours'),
  done('Terminée'),
  abandoned('Abandonnée');

  const FollowUpTaskStatus(this.label);
  final String label;

  static FollowUpTaskStatus fromStored(String value) {
    final normalized = value.trim();
    if (normalized.startsWith('[WAITING]')) return FollowUpTaskStatus.waiting;
    if (normalized.startsWith('[IN_PROGRESS]')) {
      return FollowUpTaskStatus.inProgress;
    }
    if (normalized.startsWith('[DONE]')) return FollowUpTaskStatus.done;
    if (normalized.startsWith('[ABANDONED]')) {
      return FollowUpTaskStatus.abandoned;
    }
    return FollowUpTaskStatus.waiting;
  }

  String toStoredToken() {
    switch (this) {
      case FollowUpTaskStatus.waiting:
        return 'WAITING';
      case FollowUpTaskStatus.inProgress:
        return 'IN_PROGRESS';
      case FollowUpTaskStatus.done:
        return 'DONE';
      case FollowUpTaskStatus.abandoned:
        return 'ABANDONED';
    }
  }
}

class VisitFollowUpTask {
  final String text;
  final FollowUpTaskStatus status;

  const VisitFollowUpTask({
    required this.text,
    this.status = FollowUpTaskStatus.waiting,
  });

  String toStoredString() => '[${status.toStoredToken()}] $text';

  static VisitFollowUpTask fromStored(String value) {
    final raw = value.trim();
    if (raw.isEmpty) {
      return const VisitFollowUpTask(text: '');
    }

    final status = FollowUpTaskStatus.fromStored(raw);
    final token = switch (status) {
      FollowUpTaskStatus.waiting => '[WAITING]',
      FollowUpTaskStatus.inProgress => '[IN_PROGRESS]',
      FollowUpTaskStatus.done => '[DONE]',
      FollowUpTaskStatus.abandoned => '[ABANDONED]',
    };

    final text = raw.startsWith(token)
        ? raw.substring(token.length).trim()
        : raw;

    return VisitFollowUpTask(text: text.trim(), status: status);
  }
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

  /// ID du contact principal (référence vers shared_contacts), optionnel.
  @HiveField(21)
  String? contactId;

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

  /// Tâches de suivi à clôturer après le rendez-vous.
  @HiveField(20)
  List<String>? followUpTasks;

  Visit({
    required this.id,
    required this.year,
    required this.clientId,
    this.contactId,
    this.ivIds,
    this.planEntryIds,
    this.actionIds,
    this.productRangeIds,
    this.documentPaths,
    this.visitFrameId,
    this.followUpTasks = const [],
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
  }) : createdAt = createdAt ?? DateTime.now(),
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
  String? get planEntryId =>
      planEntryIds?.isNotEmpty == true ? planEntryIds!.first : null;

  /// Premier ID d'action (pour compatibilité ascendante).
  /// Retourne null si aucun actionIds n'est défini.
  String? get actionId =>
      actionIds?.isNotEmpty == true ? actionIds!.first : null;

  /// Vrai si la visite a des gammes de produits associées.
  bool get hasProductRanges =>
      productRangeIds != null && productRangeIds!.isNotEmpty;

  /// Vrai si la visite a des documents joints.
  bool get hasDocuments => documentPaths != null && documentPaths!.isNotEmpty;

  static String normalizeFollowUpTaskText(String value) {
    return VisitFollowUpTask.fromStored(value).text;
  }

  List<VisitFollowUpTask> get followUpTaskEntries => (followUpTasks ?? [])
      .map(VisitFollowUpTask.fromStored)
      .where((task) => task.text.trim().isNotEmpty)
      .toList();

  /// Vrai si la visite a des tâches de suivi après le RDV.
  bool get hasFollowUpTasks => followUpTaskEntries.isNotEmpty;

  /// Tâches de suivi restantes, sans éléments vides et sans marqueur de statut.
  List<String> get normalizedFollowUpTasks =>
      followUpTaskEntries.map((task) => task.text).toList();

  List<String> get pendingFollowUpTasks => normalizedFollowUpTasks;

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
