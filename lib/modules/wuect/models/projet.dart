import 'package:hive/hive.dart';

part 'projet.g.dart';

/// Projet de comparatif énergétique WUECT.
///
/// Entité du module WUECT (box `wuect_projets`), référencant les entités
/// partagées Sebae par leur UUID : [contactId] (box `shared_contacts`) et
/// [ivId] (box `shared_ivs`).
@HiveType(typeId: 30)
class Projet {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final String nomSite;

  /// UUID du contact associé (box partagée `shared_contacts`).
  @HiveField(2)
  final String contactId;

  @HiveField(3)
  final double coutEnergie; // €/kWh

  @HiveField(4)
  final double pourcentageAugmentationEnergie; // % par an (ex: 5.0 pour 5%)

  @HiveField(5)
  final double percentagePerteRendement; // µCoef (ex: 0.01 pour 1%)

  /// UUID de l'Ingénieur des Ventes associé (box partagée `shared_ivs`).
  @HiveField(6)
  final String? ivId;

  Projet({
    this.id,
    required this.nomSite,
    required this.contactId,
    required this.coutEnergie,
    required this.pourcentageAugmentationEnergie,
    required this.percentagePerteRendement,
    this.ivId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomSite': nomSite,
      'contactId': contactId,
      'ivId': ivId,
      'coutEnergie': coutEnergie,
      'pourcentageAugmentationEnergie': pourcentageAugmentationEnergie,
      'percentagePerteRendement': percentagePerteRendement,
    };
  }

  factory Projet.fromMap(Map<String, dynamic> map) {
    return Projet(
      id: map['id'],
      nomSite: map['nomSite'] ?? '',
      contactId: map['contactId'] ?? '',
      ivId: map['ivId'],
      coutEnergie: (map['coutEnergie'] ?? 0.0).toDouble(),
      pourcentageAugmentationEnergie:
          (map['pourcentageAugmentationEnergie'] ?? 0.0).toDouble(),
      percentagePerteRendement:
          (map['percentagePerteRendement'] ?? 0.0).toDouble(),
    );
  }

  Projet copyWith({
    int? id,
    String? nomSite,
    String? contactId,
    String? ivId,
    double? coutEnergie,
    double? pourcentageAugmentationEnergie,
    double? percentagePerteRendement,
  }) {
    return Projet(
      id: id ?? this.id,
      nomSite: nomSite ?? this.nomSite,
      contactId: contactId ?? this.contactId,
      ivId: ivId ?? this.ivId,
      coutEnergie: coutEnergie ?? this.coutEnergie,
      pourcentageAugmentationEnergie:
          pourcentageAugmentationEnergie ?? this.pourcentageAugmentationEnergie,
      percentagePerteRendement:
          percentagePerteRendement ?? this.percentagePerteRendement,
    );
  }
}
