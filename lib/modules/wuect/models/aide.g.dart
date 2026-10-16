// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aide.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AideAdapter extends TypeAdapter<Aide> {
  @override
  final int typeId = 33;

  @override
  Aide read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return Aide(
      nom: fields[0] as String? ?? '',
      montant: fields[1] as double? ?? 0.0,
      description: fields[2] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Aide obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.nom)
      ..writeByte(1)
      ..write(obj.montant)
      ..writeByte(2)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AideAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
