import 'package:hive/hive.dart';

part 'contact.g.dart';

/// Contact.
///
/// Entité partagée : personne de contact chez un client.
/// Stocké dans la box `shared_contacts`.
///
/// Un contact est rattaché à un client via [clientId].
@HiveType(typeId: 5)
class Contact extends HiveObject {
  @HiveField(0)
  String id;

  /// ID du client parent.
  @HiveField(1)
  String? clientId;

  @HiveField(2)
  String firstName;

  @HiveField(3)
  String lastName;

  /// Fonction / poste.
  @HiveField(4)
  String position;

  /// Téléphone direct.
  @HiveField(5)
  String phone;

  /// Téléphone mobile.
  @HiveField(6)
  String mobile;

  @HiveField(7)
  String email;

  /// Notes supplémentaires.
  @HiveField(8)
  String notes;

  /// Contact principal pour ce client.
  @HiveField(9)
  bool isPrimary;

  /// Contact actif ou inactif.
  @HiveField(10)
  bool active;

  /// Date de création.
  @HiveField(11)
  DateTime createdAt;

  /// Date de dernière modification.
  @HiveField(12)
  DateTime updatedAt;

  Contact({
    required this.id,
    this.clientId,
    required this.firstName,
    required this.lastName,
    this.position = '',
    this.phone = '',
    this.mobile = '',
    this.email = '',
    this.notes = '',
    this.isPrimary = false,
    this.active = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Nom complet.
  String get fullName => '$firstName $lastName';

  /// Nom d'affichage (fullName + position si définie).
  String get displayName =>
      position.isNotEmpty ? '$fullName - $position' : fullName;
}
