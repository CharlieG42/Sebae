// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_update.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActionUpdateAdapter extends TypeAdapter<ActionUpdate> {
  @override
  final int typeId = 23;

  @override
  ActionUpdate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActionUpdate(
      date: fields[0] as DateTime,
      progress: fields[1] as int,
      comment: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ActionUpdate obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.progress)
      ..writeByte(2)
      ..write(obj.comment);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionUpdateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
