import 'package:hive/hive.dart';

part 'client_group.g.dart';

/// Groupe de clients.
///
/// Entite partagée : regroupement commercial de clients (ex. par secteur,
/// par agglomération...). Stocké dans la box `shared_client_groups`.
@HiveType(typeId: 2)
class ClientGroup extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  ClientGroup({
    required this.id,
    required this.name,
    this.description = '',
  });
}
