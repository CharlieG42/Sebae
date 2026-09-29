// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClientAdapter extends TypeAdapter<Client> {
  @override
  final int typeId = 4;

  @override
  Client read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Client(
      id: fields[0] as String,
      name: fields[1] as String,
      shortName: fields[2] as String,
      description: fields[3] as String,
      address: fields[4] as String,
      postalCode: fields[5] as String,
      city: fields[6] as String,
      country: fields[7] as String,
      phone: fields[8] as String,
      email: fields[9] as String,
      website: fields[10] as String,
      sector: fields[11] as String,
      annualRevenue: fields[12] as double?,
      employeeCount: fields[13] as int?,
      active: fields[14] as bool,
      clientNumber: fields[17] as String,
      clientGroupId: fields[18] as String?,
      clientTypeId: fields[19] as String?,
      createdAt: fields[15] as DateTime?,
      updatedAt: fields[16] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Client obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.shortName)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.postalCode)
      ..writeByte(6)
      ..write(obj.city)
      ..writeByte(7)
      ..write(obj.country)
      ..writeByte(8)
      ..write(obj.phone)
      ..writeByte(9)
      ..write(obj.email)
      ..writeByte(10)
      ..write(obj.website)
      ..writeByte(11)
      ..write(obj.sector)
      ..writeByte(12)
      ..write(obj.annualRevenue)
      ..writeByte(13)
      ..write(obj.employeeCount)
      ..writeByte(14)
      ..write(obj.active)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt)
      ..writeByte(17)
      ..write(obj.clientNumber)
      ..writeByte(18)
      ..write(obj.clientGroupId)
      ..writeByte(19)
      ..write(obj.clientTypeId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
