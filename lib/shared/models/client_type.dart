import 'package:hive/hive.dart';

part 'client_type.g.dart';

/// Type de clients.
///
/// Entite partagée : catégorie commerciale de clients (ex. industrie,
/// collectivité, agriculture...). Stocké dans la box `shared_client_types`.
@HiveType(typeId: 3)
class ClientType extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  ClientType({
    required this.id,
    required this.name,
  });
}
