import 'package:hive/hive.dart';

import 'aide.dart';

part 'systeme.g.dart';

@HiveType(typeId: 31)
class Systeme {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final int projetId; // Référence au projet

  @HiveField(2)
  final String nom; // "Ancien Système" ou "Nouveau Système"

  @HiveField(3)
  final double coutInvestissementTotal; // €

  @HiveField(4)
  final List<Aide> aides;

  double get montantAidesTotal =>
      aides.fold(0.0, (sum, aide) => sum + aide.montant);

  double get coutInvestissementNet =>
      (coutInvestissementTotal - montantAidesTotal).clamp(0.0, double.infinity);

  Systeme({
    this.id,
    required this.projetId,
    required this.nom,
    this.coutInvestissementTotal = 0.0,
    this.aides = const [],
  });

  // Conversion en Map pour SQLite (gardé pour compatibilité)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projetId': projetId,
      'nom': nom,
      'coutInvestissementTotal': coutInvestissementTotal,
      'aides': aides.map((aide) => aide.toMap()).toList(),
    };
  }

  // Création depuis un Map (SQLite) (gardé pour compatibilité)
  factory Systeme.fromMap(Map<String, dynamic> map) {
    final rawAides = map['aides'];
    final aides = <Aide>[];

    if (rawAides is List) {
      for (final rawAide in rawAides) {
        if (rawAide is Map) {
          aides.add(Aide.fromMap(Map<String, dynamic>.from(rawAide)));
        }
      }
    }

    return Systeme(
      id: map['id'],
      projetId: map['projetId'] ?? 0,
      nom: map['nom'] ?? '',
      coutInvestissementTotal: (map['coutInvestissementTotal'] ?? 0.0)
          .toDouble(),
      aides: aides,
    );
  }

  // Copie avec modification
  Systeme copyWith({
    int? id,
    int? projetId,
    String? nom,
    double? coutInvestissementTotal,
    List<Aide>? aides,
  }) {
    return Systeme(
      id: id ?? this.id,
      projetId: projetId ?? this.projetId,
      nom: nom ?? this.nom,
      coutInvestissementTotal:
          coutInvestissementTotal ?? this.coutInvestissementTotal,
      aides: aides ?? this.aides,
    );
  }
}
