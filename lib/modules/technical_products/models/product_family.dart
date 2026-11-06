import 'package:hive/hive.dart';

/// Familles de produits techniques standardisées
/// Ces familles permettent une meilleure catégorisation et un filtrage plus efficace
@HiveType(typeId: 41)
enum ProductFamily {
  @HiveField(0)
  pompage(
    displayName: 'Pompage',
    description: 'Pompes et systèmes de pompage',
    keywords: ['pompe', 'pump', 'pumping', 'relevage', 'circulation', 'transfert'],
  ),

  @HiveField(1)
  traitement(
    displayName: 'Traitement',
    description: 'Traitement des eaux et fluides',
    keywords: ['traitement', 'filtration', 'désinfection', 'station', 'épuration'],
  ),

  @HiveField(2)
  instrumentation(
    displayName: 'Instrumentation',
    description: 'Capteurs, mesure et contrôle',
    keywords: ['capteur', 'sensor', 'mesure', 'measurement', 'contrôle', 'control', 'instrumentation', 'transmetteur'],
  ),

  @HiveField(3)
  securite(
    displayName: 'Sécurité',
    description: 'Systèmes de sécurité et protection',
    keywords: ['sécurité', 'safety', 'alarme', 'protection', 'générateur', 'précaution'],
  ),

  @HiveField(4)
  energie(
    displayName: 'Énergie',
    description: 'Solutions énergétiques et électriques',
    keywords: ['énergie', 'energy', 'kwh', 'consommation', 'moteur', 'motor', 'alimentation'],
  ),

  @HiveField(5)
  mesure(
    displayName: 'Mesure',
    description: 'Appareils de mesure et analyse',
    keywords: ['mesure', 'measure', 'analyse', 'analysis', 'débitmètre', 'flowmeter'],
  ),

  @HiveField(6)
  filtration(
    displayName: 'Filtration',
    description: 'Systèmes de filtration',
    keywords: ['filtration', 'filtre', 'filter', 'purification'],
  ),

  @HiveField(7)
  irrigation(
    displayName: 'Irrigation',
    description: 'Systèmes d\'irrigation et arrosage',
    keywords: ['irrigation', 'arrosage', 'irrigation', 'sprinkler'],
  ),

  @HiveField(8)
  unknown(
    displayName: 'Autre',
    description: 'Autres produits techniques',
    keywords: [],
  );

  final String displayName;
  final String description;
  final List<String> keywords;

  const ProductFamily({
    required this.displayName,
    required this.description,
    required this.keywords,
  });

  /// Récupère une famille à partir de son nom
  static ProductFamily fromName(String name) {
    for (final family in values) {
      if (family.displayName.toLowerCase() == name.toLowerCase()) {
        return family;
      }
    }
    return ProductFamily.unknown;
  }

  /// Détermine la famille la plus pertinente à partir d'un texte
  static ProductFamily inferFromText(String text) {
    final lowerText = text.toLowerCase();
    var bestMatch = ProductFamily.unknown;
    var bestScore = 0;

    for (final family in values) {
      final score = family.keywords
          .map((keyword) => keyword.toLowerCase())
          .toSet()
          .where((keyword) => lowerText.contains(keyword))
          .length;

      if (score > bestScore) {
        bestScore = score;
        bestMatch = family;
      }
    }

    return bestMatch;
  }

  /// Liste des noms de familles pour affichage
  static List<String> get displayNames => values.map((f) => f.displayName).toList();

  @override
  String toString() => displayName;
}

/// Adapter Hive pour ProductFamily
class ProductFamilyAdapter extends TypeAdapter<ProductFamily> {
  @override
  final int typeId = 41;

  @override
  ProductFamily read(BinaryReader reader) {
    final index = reader.readByte();
    return ProductFamily.values[index];
  }

  @override
  void write(BinaryWriter writer, ProductFamily obj) {
    writer.writeByte(obj.index);
  }
}
