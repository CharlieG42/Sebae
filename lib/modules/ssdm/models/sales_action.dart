import 'package:hive/hive.dart';

import 'action_step.dart';
import 'action_update.dart';

part 'sales_action.g.dart';

/// Statut d'une action.
enum ActionStatus {
  planned('Planifiée'),
  inProgress('En cours'),
  done('Terminée'),
  cancelled('Annulée');

  const ActionStatus(this.label);
  final String label;
}

/// Action commerciale / de développement.
///
/// Une action peut être rattachée à un IV précise ([ivId] non null) ou être
/// une action d'équipe ([ivId] null), commune à toute l'équipe. L'avancement
/// est suivi via [progress] (0-100) et l'historique des mises à jour.
///
/// Une action peut être liée à une ligne du Sales Plan ([planEntryId]) afin
/// de piloter les actions qui concourent à un objectif de CA précis.
@HiveType(typeId: 22)
class SalesAction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int year;

  @HiveField(2)
  String title;

  @HiveField(3)
  String description;

  /// IV responsable. Null => action commune à l'équipe.
  @HiveField(4)
  String? ivId;

  @HiveField(5)
  String? clientGroupId;

  @HiveField(6)
  String? clientTypeId;

  /// Statut stocké sous forme d'index (voir [ActionStatus]).
  @HiveField(7)
  int statusIndex;

  /// Avancement en pourcentage (0-100).
  @HiveField(8)
  int progress;

  @HiveField(9)
  DateTime? dueDate;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  List<ActionUpdate> history;

  /// Ligne du Sales Plan à laquelle cette action est liée (optionnel).
  /// Null => action non liée à une ligne de plan.
  @HiveField(12)
  String? planEntryId;

  /// Étapes pondérées de l'action (optionnel).
  ///
  /// Null ou vide => avancement manuel via [progress].
  /// Non vide => l'avancement est calculé depuis les étapes
  /// (voir [computedProgress]).
  @HiveField(13)
  List<ActionStep>? steps;

  SalesAction({
    required this.id,
    required this.year,
    required this.title,
    this.description = '',
    this.ivId,
    this.clientGroupId,
    this.clientTypeId,
    // 0 = ActionStatus.planned.index (valeur par défaut non const
    // interdite en Dart, donc codée en dur ici).
    this.statusIndex = 0,
    this.progress = 0,
    this.dueDate,
    DateTime? createdAt,
    List<ActionUpdate>? history,
    this.planEntryId,
    this.steps,
  })  : createdAt = createdAt ?? DateTime.now(),
        history = history ?? [];

  ActionStatus get status => ActionStatus.values[statusIndex];

  set status(ActionStatus value) => statusIndex = value.index;

  /// Enregistre une mise à jour d'avancement.
  void logUpdate(int newProgress, {String comment = ''}) {
    progress = newProgress.clamp(0, 100);
    history.add(
      ActionUpdate(date: DateTime.now(), progress: progress, comment: comment),
    );
    if (progress >= 100 && status != ActionStatus.done) {
      status = ActionStatus.done;
    } else if (progress > 0 && status == ActionStatus.planned) {
      status = ActionStatus.inProgress;
    }
  }

  // ------------------------------------------------- Étapes et avancement ---

  /// Vrai si l'action est pilotée par des étapes pondérées.
  bool get hasSteps => steps != null && steps!.isNotEmpty;

  /// Étapes non annulées (celles qui comptent dans le calcul).
  List<ActionStep> get activeSteps =>
      hasSteps ? steps!.where((s) => s.status != ActionStepStatus.cancelled).toList() : <ActionStep>[];

  /// Nombre d'étapes faites sur les étapes actives.
  int get doneStepCount =>
      activeSteps.where((s) => s.status == ActionStepStatus.done).length;

  /// Avancement calculé depuis les étapes pondérées (0-100).
  /// Renvoie -1 si l'action n'a pas d'étapes.
  int get computedProgress {
    if (!hasSteps) return -1;
    final active = activeSteps;
    if (active.isEmpty) return 0;
    final totalWeight =
        active.fold(0, (sum, s) => sum + (s.weight <= 0 ? 1 : s.weight));
    final doneWeight = active.fold(
        0,
        (sum, s) =>
            s.status == ActionStepStatus.done ? sum + (s.weight <= 0 ? 1 : s.weight) : sum);
    return ((doneWeight / totalWeight) * 100).round().clamp(0, 100);
  }

  /// Avancement utilisé partout dans l'UI : calculé si étapes, sinon manuel.
  int get effectiveProgress => hasSteps ? computedProgress : progress;

  /// Vrai si au moins une étape active est bloquée.
  bool get isBlocked => activeSteps.any((s) => s.status == ActionStepStatus.blocked);

  /// Vrai si l'action (ou une de ses étapes) est en retard.
  bool get isLate {
    final actionLate = dueDate != null &&
        status != ActionStatus.done &&
        status != ActionStatus.cancelled &&
        dueDate!.isBefore(DateTime.now());
    return actionLate || activeSteps.any((s) => s.isLate);
  }
}
