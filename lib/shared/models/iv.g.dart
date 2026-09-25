// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iv.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IvAdapter extends TypeAdapter<Iv> {
  @override
  final int typeId = 1;

  @override
  Iv read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Iv(
      id: fields[0] as String,
      name: fields[1] as String,
      active: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Iv obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.active);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IvAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
