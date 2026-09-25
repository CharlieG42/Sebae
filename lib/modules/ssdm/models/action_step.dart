import 'package:hive/hive.dart';

part 'action_step.g.dart';

/// Statut d'une étape d'action.
enum ActionStepStatus {
  todo('À faire'),
  inProgress('En cours'),
  done('Fait'),
  blocked('Bloquée'),
  cancelled('Annulée');

  const ActionStepStatus(this.label);
  final String label;

  bool get isClosed => this == done || this == cancelled;
}

/// Étape d'une action commerciale.
///
/// Une action peut être découpée en étapes pondérées afin de calculer
/// un avancement fiable : chaque étape porte un [weight] (1 par défaut)
/// et un [status]. Les étapes annulées sont exclues du calcul.
@HiveType(typeId: 24)
class ActionStep extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String label;

  /// Poids de l'étape dans le calcul de l'avancement (>= 1).
  @HiveField(2)
  int weight;

  /// Statut stocké sous forme d'index (voir [ActionStepStatus]).
  @HiveField(3)
  int statusIndex;

  /// Échéance optionnelle de l'étape.
  @HiveField(4)
  DateTime? dueDate;

  ActionStep({
    required this.id,
    required this.label,
    this.weight = 1,
    // 0 = ActionStepStatus.todo.index (valeur non const interdite en Dart).
    this.statusIndex = 0,
    this.dueDate,
  });

  ActionStepStatus get status => ActionStepStatus.values[statusIndex];

  set status(ActionStepStatus value) => statusIndex = value.index;

  /// Étape en retard : échéance dépassée et pas encore fermée.
  bool get isLate =>
      dueDate != null && !status.isClosed && dueDate!.isBefore(DateTime.now());
}
