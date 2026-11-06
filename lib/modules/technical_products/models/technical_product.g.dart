// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technical_product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TechnicalProductAdapter extends TypeAdapter<TechnicalProduct> {
  @override
  final int typeId = 40;

  @override
  TechnicalProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final rawFamily = fields[3];
    final productFamily = switch (rawFamily) {
      ProductFamily value => value,
      String value => ProductFamily.fromName(value),
      _ => ProductFamily.unknown,
    };

    return TechnicalProduct(
      id: fields[0] as String,
      name: fields[1] as String,
      sourceFileName: fields[2] as String,
      family: productFamily,
      summary: fields[4] as String,
      keyFacts: (fields[5] as List).cast<String>(),
      extractedText: fields[6] as String,
      tags: (fields[8] as List?)?.cast<String>(),
      characteristics: (fields[9] as List?)?.cast<String>(),
      applications: (fields[11] as List?)?.cast<String>(),
      standards: (fields[12] as List?)?.cast<String>(),
      metrics: (fields[13] as Map?)?.cast<String, String>(),
      technicalSummary: fields[10] as String?,
      createdAt: fields[7] as DateTime?,
      lastModified: fields[14] as DateTime?,
      confidenceLevel: fields[15] as ConfidenceLevel?,
      validationStatus: fields[16] as ValidationStatus?,
      validatorName: fields[17] as String?,
      notes: fields[18] as String?,
      extractionScore: fields[19] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, TechnicalProduct obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.sourceFileName)
      ..writeByte(3)
      ..write(obj.productFamily)
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
      ..write(obj.confidenceLevel)
      ..writeByte(16)
      ..write(obj.validationStatus)
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
      other is TechnicalProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
