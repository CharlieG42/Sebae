import 'package:hive/hive.dart';

part 'sales_plan_entry.g.dart';

/// Ligne du Sales Plan.
///
/// Une ligne définit un objectif de CA pour un couple
/// (IV, groupe de clients, type de clients) sur une année donnée.
/// Le realizedAmount permet de suivre le CA réalisé par rapport à la cible.
///
/// Le [title] permet de donner un nom personnalisé à la ligne de plan.
@HiveType(typeId: 21)
class SalesPlanEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int year;

  /// Titre personnalisé de la ligne de plan.
  @HiveField(2)
  String title;

  /// IV concerné (id dans la box `shared_ivs`) - obsolète, remplacé par ivIds.
  @HiveField(3)
  String ivId;

  /// IDs des IV concernés (pour sélection multiple).
  @HiveField(4)
  List<String>? ivIds;

  /// Groupe de clients concerné (id dans `shared_client_groups`) - obsolète, remplacé par clientGroupIds.
  @HiveField(5)
  String clientGroupId;

  /// IDs des groupes de clients concernés (pour sélection multiple).
  @HiveField(6)
  List<String>? clientGroupIds;

  /// Type de clients concerné (id dans `shared_client_types`) - obsolète, remplacé par clientTypeIds.
  @HiveField(7)
  String clientTypeId;

  /// IDs des types de clients concernés (pour sélection multiple).
  @HiveField(8)
  List<String>? clientTypeIds;

  /// Objectif de CA pour cette ligne (en euros).
  @HiveField(9)
  double targetAmount;

  /// CA réalisé à ce jour sur cette ligne (en euros).
  @HiveField(10)
  double realizedAmount;

  SalesPlanEntry({
    required this.id,
    required this.year,
    required this.title,
    required this.ivId,
    this.ivIds,
    required this.clientGroupId,
    this.clientGroupIds,
    required this.clientTypeId,
    this.clientTypeIds,
    required this.targetAmount,
    this.realizedAmount = 0,
  });

  /// Vrai si la ligne a des IV multiples sélectionnés.
  bool get hasMultipleIvs => ivIds != null && ivIds!.length > 1;

  /// Vrai si la ligne a des groupes multiples sélectionnés.
  bool get hasMultipleGroups => clientGroupIds != null && clientGroupIds!.length > 1;

  /// Vrai si la ligne a des types multiples sélectionnés.
  bool get hasMultipleTypes => clientTypeIds != null && clientTypeIds!.length > 1;

  /// Liste effective des IV (ivIds si défini, sinon [ivId]).
  List<String> get effectiveIvIds => ivIds ?? [ivId];

  /// Liste effective des groupes (clientGroupIds si défini, sinon [clientGroupId]).
  List<String> get effectiveClientGroupIds => clientGroupIds ?? [clientGroupId];

  /// Liste effective des types (clientTypeIds si défini, sinon [clientTypeId]).
  List<String> get effectiveClientTypeIds => clientTypeIds ?? [clientTypeId];
}
