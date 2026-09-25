// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_action.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SalesActionAdapter extends TypeAdapter<SalesAction> {
  @override
  final int typeId = 22;

  @override
  SalesAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SalesAction(
      id: fields[0] as String,
      year: fields[1] as int,
      title: fields[2] as String,
      description: fields[3] as String,
      ivId: fields[4] as String?,
      clientGroupId: fields[5] as String?,
      clientTypeId: fields[6] as String?,
      statusIndex: fields[7] as int,
      progress: fields[8] as int,
      dueDate: fields[9] as DateTime?,
      createdAt: fields[10] as DateTime?,
      history: (fields[11] as List?)?.cast<ActionUpdate>(),
      planEntryId: fields[12] as String?,
      steps: (fields[13] as List?)?.cast<ActionStep>(),
    );
  }

  @override
  void write(BinaryWriter writer, SalesAction obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.year)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.ivId)
      ..writeByte(5)
      ..write(obj.clientGroupId)
      ..writeByte(6)
      ..write(obj.clientTypeId)
      ..writeByte(7)
      ..write(obj.statusIndex)
      ..writeByte(8)
      ..write(obj.progress)
      ..writeByte(9)
      ..write(obj.dueDate)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.history)
      ..writeByte(12)
      ..write(obj.planEntryId)
      ..writeByte(13)
      ..write(obj.steps);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalesActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
