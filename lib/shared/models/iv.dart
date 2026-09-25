import 'package:hive/hive.dart';

part 'iv.g.dart';

/// Ingénieur des Ventes (IV).
///
/// Entité partagée : employé(e) de l'équipe commerciale. Les données des IV
/// sont stockées dans la box `shared_ivs` et sont accessibles à tous les
/// modules Sebae (SSDM, WUECT à venir...).
///
/// Le [id] (UUID) sert de clé Hive : les autres entités référencent les IV
/// par cet id, jamais par la clé auto-incrémentée de la box.
@HiveType(typeId: 1)
class Iv extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// Trigramme société (ex. "DBA"). Convention interne WildZimut.
  @HiveField(3)
  String trigram;

  @HiveField(2)
  bool active;

  Iv({
    required this.id,
    required this.name,
    this.trigram = '',
    this.active = true,
  });

  /// Libellé court pour les listes : trigramme si défini, sinon initiale.
  String get shortLabel =>
      trigram.isNotEmpty ? trigram : (name.isNotEmpty ? name[0] : '?');
}
