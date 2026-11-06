import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'product_family.dart';
import 'validation_status.dart';

part 'technical_product.g.dart';

@HiveType(typeId: 40)
class TechnicalProduct extends HiveObject {
  TechnicalProduct({
    required this.id,
    required this.name,
    required this.sourceFileName,
    ProductFamily? family,
    required this.summary,
    required this.keyFacts,
    required this.extractedText,
    List<String>? tags,
    List<String>? characteristics,
    List<String>? applications,
    List<String>? standards,
    Map<String, String>? metrics,
    String? technicalSummary,
    DateTime? createdAt,
    DateTime? lastModified,
    ConfidenceLevel? confidenceLevel,
    ValidationStatus? validationStatus,
    this.validatorName,
    this.notes,
    int? extractionScore,
  }) : productFamily = family ?? ProductFamily.unknown,
        tags = tags ?? const [],
        characteristics = characteristics ?? const [],
        applications = applications ?? const [],
        standards = standards ?? const [],
        metrics = metrics ?? const <String, String>{},
        technicalSummary = technicalSummary ?? summary,
        createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now(),
        confidenceLevel = confidenceLevel ?? ConfidenceLevel.medium,
        validationStatus = validationStatus ?? ValidationStatus.autoExtracted,
        extractionScore = extractionScore ?? 0;

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String sourceFileName;

  @HiveField(3)
  ProductFamily productFamily;

  @HiveField(4)
  String summary;

  @HiveField(5)
  List<String> keyFacts;

  @HiveField(6)
  String extractedText;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  List<String> tags;

  @HiveField(9)
  List<String> characteristics;

  @HiveField(10)
  String technicalSummary;

  @HiveField(11)
  List<String> applications;

  @HiveField(12)
  List<String> standards;

  @HiveField(13)
  Map<String, String> metrics;

  @HiveField(14)
  DateTime lastModified;

  @HiveField(15)
  ConfidenceLevel confidenceLevel;

  @HiveField(16)
  ValidationStatus validationStatus;

  @HiveField(17)
  String? validatorName;

  @HiveField(18)
  String? notes;

  @HiveField(19)
  int extractionScore;

  /// Get display name for product family
  String get familyDisplayName => productFamily.displayName;

  /// Get color for validation status
  Color get statusColor => validationStatus.color;

  /// Get color for confidence level
  Color get confidenceColor => confidenceLevel.color;

  /// Check if product has been modified since creation
  bool get hasBeenModified => lastModified != createdAt;

  /// Get a summary of the validation state
  String get validationSummary {
    final parts = <String>[];
    
    if (validationStatus != ValidationStatus.autoExtracted) {
      parts.add(validationStatus.displayName);
    }
    
    if (validatorName != null && validatorName!.isNotEmpty) {
      parts.add('par $validatorName');
    }
    
    return parts.join(' ');
  }
}
