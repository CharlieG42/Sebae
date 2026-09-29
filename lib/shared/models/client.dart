import 'package:hive/hive.dart';

part 'client.g.dart';

/// Client.
///
/// Entité partagée : entreprise ou organisation cliente.
/// Stocké dans la box `shared_clients`.
///
/// Un client peut avoir plusieurs contacts (voir [Contact]).
@HiveType(typeId: 4)
class Client extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// Nom court ou raison sociale.
  @HiveField(2)
  String shortName;

  @HiveField(3)
  String description;

  /// Adresse.
  @HiveField(4)
  String address;

  /// Code postal.
  @HiveField(5)
  String postalCode;

  /// Ville.
  @HiveField(6)
  String city;

  /// Pays.
  @HiveField(7)
  String country;

  /// Téléphone principal.
  @HiveField(8)
  String phone;

  /// Email principal.
  @HiveField(9)
  String email;

  /// Site web.
  @HiveField(10)
  String website;

  /// Secteur d'activité.
  @HiveField(11)
  String sector;

  /// Chiffre d'affaires annuel (optionnel).
  @HiveField(12)
  double? annualRevenue;

  /// Nombre d'employés (optionnel).
  @HiveField(13)
  int? employeeCount;

  /// Client actif ou inactif.
  @HiveField(14)
  bool active;

  /// Date de création du client.
  @HiveField(15)
  DateTime createdAt;

  /// Date de dernière modification.
  @HiveField(16)
  DateTime updatedAt;

  /// Numéro de client unique.
  @HiveField(17)
  String clientNumber;

  /// ID du groupe de clients.
  @HiveField(18)
  String? clientGroupId;

  /// ID du type de client.
  @HiveField(19)
  String? clientTypeId;

  Client({
    required this.id,
    required this.name,
    this.shortName = '',
    this.description = '',
    this.address = '',
    this.postalCode = '',
    this.city = '',
    this.country = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.sector = '',
    this.annualRevenue,
    this.employeeCount,
    this.active = true,
    this.clientNumber = '',
    this.clientGroupId,
    this.clientTypeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Nom d'affichage (shortName si défini, sinon name).
  String get displayName => shortName.isNotEmpty ? shortName : name;
}
