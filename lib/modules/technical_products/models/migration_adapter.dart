import 'package:hive/hive.dart';

import 'product_family.dart';
import 'validation_status.dart';
import 'technical_product.dart';

/// Adapter de migration pour les anciens produits avec family en String
class LegacyTechnicalProductAdapter extends TypeAdapter<TechnicalProduct> {
  @override
  final int typeId = 40;

  @override
  TechnicalProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    // Handle legacy string productFamily
    final legacyFamily = fields[3];
    ProductFamily family;
    
    if (legacyFamily is String) {
      family = ProductFamily.fromName(legacyFamily);
    } else if (legacyFamily is ProductFamily) {
      family = legacyFamily;
    } else {
      family = ProductFamily.unknown;
    }
    
    // Handle legacy validationStatus (default to autoExtracted)
    ValidationStatus status = fields[16] as ValidationStatus? ?? ValidationStatus.autoExtracted;
    
    // Handle legacy confidenceLevel (default to medium)
    ConfidenceLevel confidence = fields[15] as ConfidenceLevel? ?? ConfidenceLevel.medium;
    
    return TechnicalProduct(
      id: fields[0] as String,
      name: fields[1] as String,
      sourceFileName: fields[2] as String,
      family: family,
      summary: fields[4] as String,
      keyFacts: (fields[5] as List).cast<String>(),
      extractedText: fields[6] as String,
      tags: (fields[8] as List?)?.cast<String>(),
      characteristics: (fields[9] as List?)?.cast<String>(),
      technicalSummary: fields[10] as String?,
      applications: (fields[11] as List?)?.cast<String>(),
      standards: (fields[12] as List?)?.cast<String>(),
      metrics: (fields[13] as Map?)?.cast<String, String>(),
      createdAt: fields[7] as DateTime?,
      lastModified: fields[14] as DateTime? ?? fields[7] as DateTime? ?? DateTime.now(),
      confidenceLevel: confidence,
      validationStatus: status,
      validatorName: fields[17] as String?,
      notes: fields[18] as String?,
      extractionScore: fields[19] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, TechnicalProduct obj) {
    writer
      ..writeByte(20) // Updated to 20 fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.sourceFileName)
      ..writeByte(3)
      ..write(obj.productFamily.index)
      ..writeByte(4)
      ..write(obj.summary)
      ..writeByte(5)
      ..write(obj.keyFacts)
      ..writeByte(6)
      ..write(obj.extractedText)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.characteristics)
      ..writeByte(10)
      ..write(obj.technicalSummary)
      ..writeByte(11)
      ..write(obj.applications)
      ..writeByte(12)
      ..write(obj.standards)
      ..writeByte(13)
      ..write(obj.metrics)
      ..writeByte(14)
      ..write(obj.lastModified)
      ..writeByte(15)
      ..write(obj.confidenceLevel.index)
      ..writeByte(16)
      ..write(obj.validationStatus.index)
      ..writeByte(17)
      ..write(obj.validatorName)
      ..writeByte(18)
      ..write(obj.notes)
      ..writeByte(19)
      ..write(obj.extractionScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegacyTechnicalProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
