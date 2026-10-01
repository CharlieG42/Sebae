import 'package:hive/hive.dart';

part 'wuect_legacy_models.g.dart';

/// Modèles legacy WUECT (format de données antérieur à l'intégration dans
/// Sebae), utilisés uniquement pour la migration.
///
/// Ces classes reproduisent à l'identique les anciens modèles du dépôt WUECT
/// (mêmes typeIds 0-3, mêmes champs) afin de relire les anciennes boxes Hive
/// (`contacts`, `projets`, `systemes`, `pompes`) et d'en migrer le contenu
/// vers les boxes de Sebae. Elles ne doivent servir qu'à la lecture.
///
/// Les adapters ne sont enregistrés que dans l'isolate de migration (voir
/// `wuect_legacy_migration.dart`) car leurs typeIds entrent en conflit avec
/// ceux des modèles actuels de Sebae.

@HiveType(typeId: 0)
class LegacyContact {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final String client;

  @HiveField(2)
  final String nom;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String mobile;

  LegacyContact({
    this.id,
    required this.client,
    required this.nom,
    required this.email,
    required this.mobile,
  });
}

@HiveType(typeId: 1)
class LegacyProjet {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final String nomSite;

  @HiveField(2)
  final int contactId;

  @HiveField(3)
  final double coutEnergie;

  @HiveField(4)
  final double pourcentageAugmentationEnergie;

  @HiveField(5)
  final double percentagePerteRendement;

  @HiveField(6)
  final int? ivId;

  LegacyProjet({
    this.id,
    required this.nomSite,
    required this.contactId,
    required this.coutEnergie,
    required this.pourcentageAugmentationEnergie,
    required this.percentagePerteRendement,
    this.ivId,
  });
}

@HiveType(typeId: 2)
class LegacySysteme {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final int projetId;

  @HiveField(2)
  final String nom;

  @HiveField(3)
  final double coutInvestissementTotal;

  LegacySysteme({
    this.id,
    required this.projetId,
    required this.nom,
    this.coutInvestissementTotal = 0.0,
  });
}

@HiveType(typeId: 3)
class LegacyPompe {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final int systemeId;

  @HiveField(2)
  final String marque;

  @HiveField(3)
  final String modele;

  @HiveField(4)
  final double puissanceNominale;

  @HiveField(5)
  final double debit;

  @HiveField(6)
  final double hmt;

  @HiveField(7)
  final double rendementInitialPompe;

  @HiveField(8)
  final double rendementInitialMoteur;

  @HiveField(9)
  final int anneeInstallation;

  @HiveField(10)
  final int heuresFonctionnement;

  @HiveField(11)
  final double coutInvestissement;

  @HiveField(12)
  final double p1Estimee;

  LegacyPompe({
    this.id,
    required this.systemeId,
    required this.marque,
    required this.modele,
    required this.puissanceNominale,
    required this.debit,
    required this.hmt,
    required this.rendementInitialPompe,
    required this.rendementInitialMoteur,
    required this.anneeInstallation,
    required this.heuresFonctionnement,
    required this.coutInvestissement,
    this.p1Estimee = 0.0,
  });
}
