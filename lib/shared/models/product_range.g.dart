// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_range.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductRangeAdapter extends TypeAdapter<ProductRange> {
  @override
  final int typeId = 6;

  @override
  ProductRange read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductRange(
      id: fields[0] as String,
      name: fields[1] as String,
      code: fields[2] as String,
      description: fields[3] as String,
      parentId: fields[4] as String?,
      averagePrice: fields[5] as double?,
      averageMargin: fields[6] as double?,
      active: fields[7] as bool,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductRange obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.code)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.parentId)
      ..writeByte(5)
      ..write(obj.averagePrice)
      ..writeByte(6)
      ..write(obj.averageMargin)
      ..writeByte(7)
      ..write(obj.active)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductRangeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
