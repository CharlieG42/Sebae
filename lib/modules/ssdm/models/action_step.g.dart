// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_step.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActionStepAdapter extends TypeAdapter<ActionStep> {
  @override
  final int typeId = 24;

  @override
  ActionStep read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActionStep(
      id: fields[0] as String,
      label: fields[1] as String,
      weight: fields[2] as int,
      statusIndex: fields[3] as int,
      dueDate: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ActionStep obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.statusIndex)
      ..writeByte(4)
      ..write(obj.dueDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionStepAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
