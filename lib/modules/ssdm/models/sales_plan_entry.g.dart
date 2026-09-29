// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_plan_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SalesPlanEntryAdapter extends TypeAdapter<SalesPlanEntry> {
  @override
  final int typeId = 21;

  @override
  SalesPlanEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SalesPlanEntry(
      id: fields[0] as String,
      year: fields[1] as int,
      title: fields[2] as String,
      ivId: fields[3] as String,
      ivIds: (fields[4] as List?)?.cast<String>(),
      clientGroupId: fields[5] as String,
      clientGroupIds: (fields[6] as List?)?.cast<String>(),
      clientTypeId: fields[7] as String,
      clientTypeIds: (fields[8] as List?)?.cast<String>(),
      targetAmount: fields[9] as double,
      realizedAmount: fields[10] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SalesPlanEntry obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.year)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.ivId)
      ..writeByte(4)
      ..write(obj.ivIds)
      ..writeByte(5)
      ..write(obj.clientGroupId)
      ..writeByte(6)
      ..write(obj.clientGroupIds)
      ..writeByte(7)
      ..write(obj.clientTypeId)
      ..writeByte(8)
      ..write(obj.clientTypeIds)
      ..writeByte(9)
      ..write(obj.targetAmount)
      ..writeByte(10)
      ..write(obj.realizedAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalesPlanEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
