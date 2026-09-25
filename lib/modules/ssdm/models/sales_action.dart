import 'package:hive/hive.dart';

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

/// Action commerciale / de développément.
///
/// Une action peut être rattachée à un IV precise ([ivId] non null) ou etre
/// une action d'équipe ([ivId] null), commune à toute l'équipe. L'avancement
/// est suivi via [progress] (0-100) et l'historique des mises à jour.
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

  SalesAction({
    required this.id,
    required this.year,
    required this.title,
    this.description = '',
    this.ivId,
    this.clientGroupId,
    this.clientTypeId,
    this.statusIndex = ActionStatus.planned.index,
    this.progress = 0,
    this.dueDate,
    DateTime? createdAt,
    List<ActionUpdate>? history,
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
}
