import 'package:hive/hive.dart';

part 'ssdm_year.g.dart';

/// Année de gestion SSDM.
///
/// Une année est créée via "Créer une nouvelle année" : c'est à ce moment
/// que l'objectif de CA est défini, puis que le Sales Plan et les actions
/// sont construits. Clé Hive : `year.toString()`.
@HiveType(typeId: 20)
class SsdmYear extends HiveObject {
  @HiveField(0)
  int year;

  /// Objectif de chiffre d'affaires pour l'année (en euros).
  @HiveField(1)
  double caObjective;

  @HiveField(2)
  DateTime createdAt;

  SsdmYear({
    required this.year,
    required this.caObjective,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
