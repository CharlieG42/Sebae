import 'package:hive/hive.dart';

part 'iv.g.dart';

/// Ingénieur des Ventes (IV).
///
/// Entite partagée : employee(e) de l'équipe commerciale. Les données des IV
/// sont stockees dans la box `shared_ivs` et sont accessibles à tous les
/// modules Sebae (SSDM, WUECT à venir...).
@HiveType(typeId: 1)
class Iv extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  bool active;

  Iv({
    required this.id,
    required this.name,
    this.active = true,
  });
}
