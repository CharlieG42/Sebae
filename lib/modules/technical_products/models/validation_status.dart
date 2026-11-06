import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Statuts de validation pour les fiches techniques
/// Permet de suivre l'état de validation et de confiance des données
@HiveType(typeId: 42)
enum ValidationStatus {
  @HiveField(0)
  autoExtracted(
    displayName: 'Auto-extrait',
    description: 'Fiche extraite automatiquement, non validée',
    colorValue: 0xFF2196F3, // Colors.blue.value
    priority: 0,
  ),

  @HiveField(1)
  toReview(
    displayName: 'À revoir',
    description: 'Fiche nécessitant une validation manuelle',
    colorValue: 0xFFFF9800, // Colors.orange.value
    priority: 1,
  ),

  @HiveField(2)
  validated(
    displayName: 'Validé',
    description: 'Fiche validée manuellement',
    colorValue: 0xFF4CAF50, // Colors.green.value
    priority: 2,
  ),

  @HiveField(3)
  manuallyModified(
    displayName: 'Modifié manuellement',
    description: 'Fiche modifiée manuellement après extraction',
    colorValue: 0xFF9C27B0, // Colors.purple.value
    priority: 3,
  );

  final String displayName;
  final String description;
  final int colorValue;
  final int priority;

  const ValidationStatus({
    required this.displayName,
    required this.description,
    required this.colorValue,
    required this.priority,
  });

  /// Get the Color object
  Color get color => Color(colorValue);

  /// Récupère un statut à partir de son nom
  static ValidationStatus fromName(String name) {
    for (final status in values) {
      if (status.displayName.toLowerCase() == name.toLowerCase()) {
        return status;
      }
    }
    return ValidationStatus.autoExtracted;
  }

  /// Liste des noms de statuts pour affichage
  static List<String> get displayNames => values.map((s) => s.displayName).toList();

  @override
  String toString() => displayName;
}

/// Niveaux de confiance pour l'extraction automatique
@HiveType(typeId: 43)
enum ConfidenceLevel {
  @HiveField(0)
  veryHigh(
    displayName: 'Très élevée',
    description: 'Extraction très fiable avec données complètes',
    scoreThreshold: 90,
    colorValue: 0xFF4CAF50, // Colors.green.value
  ),

  @HiveField(1)
  high(
    displayName: 'Élevée',
    description: 'Extraction fiable avec quelques éléments manquant',
    scoreThreshold: 70,
    colorValue: 0xFF8BC34A, // Colors.lightGreen.value
  ),

  @HiveField(2)
  medium(
    displayName: 'Moyenne',
    description: 'Extraction partielle, nécessite une vérification',
    scoreThreshold: 50,
    colorValue: 0xFFFFEB3B, // Colors.yellow.value
  ),

  @HiveField(3)
  low(
    displayName: 'Faible',
    description: 'Extraction limitée, données incomplètes',
    scoreThreshold: 30,
    colorValue: 0xFFFF9800, // Colors.orange.value
  ),

  @HiveField(4)
  veryLow(
    displayName: 'Très faible',
    description: 'Extraction minimale, nécessite une reconstruction manuelle',
    scoreThreshold: 0,
    colorValue: 0xFFF44336, // Colors.red.value
  );

  final String displayName;
  final String description;
  final int scoreThreshold;
  final int colorValue;

  const ConfidenceLevel({
    required this.displayName,
    required this.description,
    required this.scoreThreshold,
    required this.colorValue,
  });

  /// Get the Color object
  Color get color => Color(colorValue);

  /// Calcule le niveau de confiance à partir d'un score (0-100)
  static ConfidenceLevel fromScore(int score) {
    for (final level in values) {
      if (score >= level.scoreThreshold) {
        return level;
      }
    }
    return ConfidenceLevel.veryLow;
  }

  /// Liste des noms de niveaux pour affichage
  static List<String> get displayNames => values.map((l) => l.displayName).toList();

  @override
  String toString() => displayName;
}

/// Adapter Hive pour ValidationStatus
class ValidationStatusAdapter extends TypeAdapter<ValidationStatus> {
  @override
  final int typeId = 42;

  @override
  ValidationStatus read(BinaryReader reader) {
    final index = reader.readByte();
    return ValidationStatus.values[index];
  }

  @override
  void write(BinaryWriter writer, ValidationStatus obj) {
    writer.writeByte(obj.index);
  }
}

/// Adapter Hive pour ConfidenceLevel
class ConfidenceLevelAdapter extends TypeAdapter<ConfidenceLevel> {
  @override
  final int typeId = 43;

  @override
  ConfidenceLevel read(BinaryReader reader) {
    final index = reader.readByte();
    return ConfidenceLevel.values[index];
  }

  @override
  void write(BinaryWriter writer, ConfidenceLevel obj) {
    writer.writeByte(obj.index);
  }
}
