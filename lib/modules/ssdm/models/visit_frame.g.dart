// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_frame.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VisitFrameAdapter extends TypeAdapter<VisitFrame> {
  @override
  final int typeId = 26;

  @override
  VisitFrame read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VisitFrame(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      productRangeIds: (fields[3] as List?)?.cast<String>(),
      supportDocumentPaths: (fields[4] as List?)?.cast<String>(),
      createdAt: fields[5] as DateTime?,
      updatedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, VisitFrame obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.productRangeIds)
      ..writeByte(4)
      ..write(obj.supportDocumentPaths)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitFrameAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
