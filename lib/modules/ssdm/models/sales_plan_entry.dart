import 'package:hive/hive.dart';

part 'sales_plan_entry.g.dart';

/// Ligne du Sales Plan.
///
/// Une ligne définit un objectif de CA pour un couple
/// (IV, groupe de clients, type de clients) sur une année donnée.
/// Le realizedAmount permet de suivre le CA réalisé par rapport à la cible.
@HiveType(typeId: 21)
class SalesPlanEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int year;

  /// IV concerné (id dans la box `shared_ivs`).
  @HiveField(2)
  String ivId;

  /// Groupe de clients concerné (id dans `shared_client_groups`).
  @HiveField(3)
  String clientGroupId;

  /// Type de clients concerné (id dans `shared_client_types`).
  @HiveField(4)
  String clientTypeId;

  /// Objectif de CA pour cette ligne (en euros).
  @HiveField(5)
  double targetAmount;

  /// CA réalisé à ce jour sur cette ligne (en euros).
  @HiveField(6)
  double realizedAmount;

  SalesPlanEntry({
    required this.id,
    required this.year,
    required this.ivId,
    required this.clientGroupId,
    required this.clientTypeId,
    required this.targetAmount,
    this.realizedAmount = 0,
  });
}
