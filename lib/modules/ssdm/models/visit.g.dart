// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VisitAdapter extends TypeAdapter<Visit> {
  @override
  final int typeId = 25;

  @override
  Visit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Visit(
      id: fields[0] as String,
      year: fields[1] as int,
      clientId: fields[2] as String,
      ivIds: (fields[3] as List?)?.cast<String>(),
      planEntryIds: (fields[4] as List?)?.cast<String>(),
      actionIds: (fields[5] as List?)?.cast<String>(),
      productRangeIds: (fields[10] as List?)?.cast<String>(),
      documentPaths: (fields[11] as List?)?.cast<String>(),
      visitFrameId: fields[19] as String?,
      title: fields[6] as String,
      appointmentDate: fields[7] as DateTime,
      estimatedDuration: fields[8] as int,
      location: fields[9] as String,
      themes: (fields[12] as List).cast<String>(),
      notesBefore: fields[13] as String,
      notesDuring: fields[14] as String,
      notesAfter: fields[15] as String,
      statusIndex: fields[16] as int,
      createdAt: fields[17] as DateTime?,
      updatedAt: fields[18] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Visit obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.year)
      ..writeByte(2)
      ..write(obj.clientId)
      ..writeByte(3)
      ..write(obj.ivIds)
      ..writeByte(4)
      ..write(obj.planEntryIds)
      ..writeByte(5)
      ..write(obj.actionIds)
      ..writeByte(6)
      ..write(obj.title)
      ..writeByte(7)
      ..write(obj.appointmentDate)
      ..writeByte(8)
      ..write(obj.estimatedDuration)
      ..writeByte(9)
      ..write(obj.location)
      ..writeByte(10)
      ..write(obj.productRangeIds)
      ..writeByte(11)
      ..write(obj.documentPaths)
      ..writeByte(12)
      ..write(obj.themes)
      ..writeByte(13)
      ..write(obj.notesBefore)
      ..writeByte(14)
      ..write(obj.notesDuring)
      ..writeByte(15)
      ..write(obj.notesAfter)
      ..writeByte(16)
      ..write(obj.statusIndex)
      ..writeByte(17)
      ..write(obj.createdAt)
      ..writeByte(18)
      ..write(obj.updatedAt)
      ..writeByte(19)
      ..write(obj.visitFrameId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
