import 'package:hive/hive.dart';

part 'product_range.g.dart';

/// Gamme de produits.
///
/// Entité partagée : catégorie ou famille de produits.
/// Stocké dans la box `shared_product_ranges`.
@HiveType(typeId: 6)
class ProductRange extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// Code ou référence de la gamme.
  @HiveField(2)
  String code;

  @HiveField(3)
  String description;

  /// Catégorie parente (optionnel, pour hiérarchie).
  @HiveField(4)
  String? parentId;

  /// Prix moyen ou indicatif (optionnel).
  @HiveField(5)
  double? averagePrice;

  /// Marge moyenne (optionnel, en pourcentage).
  @HiveField(6)
  double? averageMargin;

  /// Gamme active ou inactive.
  @HiveField(7)
  bool active;

  /// Date de création.
  @HiveField(8)
  DateTime createdAt;

  /// Date de dernière modification.
  @HiveField(9)
  DateTime updatedAt;

  ProductRange({
    required this.id,
    required this.name,
    this.code = '',
    this.description = '',
    this.parentId,
    this.averagePrice,
    this.averageMargin,
    this.active = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Nom d'affichage (code + name si code défini).
  String get displayName =>
      code.isNotEmpty ? '$code - $name' : name;
}
