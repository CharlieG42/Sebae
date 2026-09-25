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
      ivId: fields[2] as String,
      clientGroupId: fields[3] as String,
      clientTypeId: fields[4] as String,
      targetAmount: fields[5] as double,
      realizedAmount: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SalesPlanEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.year)
      ..writeByte(2)
      ..write(obj.ivId)
      ..writeByte(3)
      ..write(obj.clientGroupId)
      ..writeByte(4)
      ..write(obj.clientTypeId)
      ..writeByte(5)
      ..write(obj.targetAmount)
      ..writeByte(6)
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
