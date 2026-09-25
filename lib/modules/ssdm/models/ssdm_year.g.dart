// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ssdm_year.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SsdmYearAdapter extends TypeAdapter<SsdmYear> {
  @override
  final int typeId = 20;

  @override
  SsdmYear read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SsdmYear(
      year: fields[0] as int,
      caObjective: fields[1] as double,
      createdAt: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SsdmYear obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.year)
      ..writeByte(1)
      ..write(obj.caObjective)
      ..writeByte(2)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SsdmYearAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
