import 'package:hive/hive.dart';

part 'visit_frame.g.dart';

/// Trame de visite - Modèle type pour ne rien oublier.
///
/// Permet de définir des trames standard avec :
/// - Gammes de produits à présenter
/// - Documents supports à projeter
///
/// Une trame peut être associée à une visite pour la pré-remplir.
@HiveType(typeId: 26)
class VisitFrame extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// Description ou objectif de la trame.
  @HiveField(2)
  String description;

  /// IDs des gammes de produits à présenter.
  @HiveField(3)
  List<String>? productRangeIds;

  /// Chemins des documents supports à projeter.
  @HiveField(4)
  List<String>? supportDocumentPaths;

  /// Date de création.
  @HiveField(5)
  DateTime createdAt;

  /// Date de dernière modification.
  @HiveField(6)
  DateTime updatedAt;

  VisitFrame({
    required this.id,
    required this.name,
    this.description = '',
    this.productRangeIds,
    this.supportDocumentPaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Vrai si la trame a des gammes de produits définies.
  bool get hasProductRanges => productRangeIds != null && productRangeIds!.isNotEmpty;

  /// Vrai si la trame a des documents supports.
  bool get hasSupportDocuments => supportDocumentPaths != null && supportDocumentPaths!.isNotEmpty;
}
