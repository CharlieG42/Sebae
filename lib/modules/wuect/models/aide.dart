import 'package:hive/hive.dart';

part 'aide.g.dart';

@HiveType(typeId: 33)
class Aide {
  @HiveField(0)
  final String nom;

  @HiveField(1)
  final double montant;

  @HiveField(2)
  final String description;

  const Aide({this.nom = '', this.montant = 0.0, this.description = ''});

  factory Aide.fromMap(Map<String, dynamic> map) {
    return Aide(
      nom: map['nom']?.toString() ?? '',
      montant: (map['montant'] ?? 0.0).toDouble(),
      description: map['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'nom': nom, 'montant': montant, 'description': description};
  }

  Aide copyWith({String? nom, double? montant, String? description}) {
    return Aide(
      nom: nom ?? this.nom,
      montant: montant ?? this.montant,
      description: description ?? this.description,
    );
  }
}
