import 'package:hive/hive.dart';

part 'action_update.g.dart';

/// Mise à jour d'avancement d'une action (entree d'historique).
@HiveType(typeId: 23)
class ActionUpdate extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  int progress;

  @HiveField(2)
  String comment;

  ActionUpdate({
    required this.date,
    required this.progress,
    this.comment = '',
  });
}
