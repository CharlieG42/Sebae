// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wuect_legacy_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LegacyContactAdapter extends TypeAdapter<LegacyContact> {
  @override
  final int typeId = 0;

  @override
  LegacyContact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LegacyContact(
      id: fields[0] as int?,
      client: fields[1] as String,
      nom: fields[2] as String,
      email: fields[3] as String,
      mobile: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LegacyContact obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.client)
      ..writeByte(2)
      ..write(obj.nom)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.mobile);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegacyContactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LegacyProjetAdapter extends TypeAdapter<LegacyProjet> {
  @override
  final int typeId = 1;

  @override
  LegacyProjet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LegacyProjet(
      id: fields[0] as int?,
      nomSite: fields[1] as String,
      contactId: fields[2] as int,
      coutEnergie: fields[3] as double,
      pourcentageAugmentationEnergie: fields[4] as double,
      percentagePerteRendement: fields[5] as double,
      ivId: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, LegacyProjet obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nomSite)
      ..writeByte(2)
      ..write(obj.contactId)
      ..writeByte(3)
      ..write(obj.coutEnergie)
      ..writeByte(4)
      ..write(obj.pourcentageAugmentationEnergie)
      ..writeByte(5)
      ..write(obj.percentagePerteRendement)
      ..writeByte(6)
      ..write(obj.ivId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegacyProjetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LegacySystemeAdapter extends TypeAdapter<LegacySysteme> {
  @override
  final int typeId = 2;

  @override
  LegacySysteme read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LegacySysteme(
      id: fields[0] as int?,
      projetId: fields[1] as int,
      nom: fields[2] as String,
      coutInvestissementTotal: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LegacySysteme obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projetId)
      ..writeByte(2)
      ..write(obj.nom)
      ..writeByte(3)
      ..write(obj.coutInvestissementTotal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegacySystemeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LegacyPompeAdapter extends TypeAdapter<LegacyPompe> {
  @override
  final int typeId = 3;

  @override
  LegacyPompe read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LegacyPompe(
      id: fields[0] as int?,
      systemeId: fields[1] as int,
      marque: fields[2] as String,
      modele: fields[3] as String,
      puissanceNominale: fields[4] as double,
      debit: fields[5] as double,
      hmt: fields[6] as double,
      rendementInitialPompe: fields[7] as double,
      rendementInitialMoteur: fields[8] as double,
      anneeInstallation: fields[9] as int,
      heuresFonctionnement: fields[10] as int,
      coutInvestissement: fields[11] as double,
      p1Estimee: fields[12] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LegacyPompe obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.systemeId)
      ..writeByte(2)
      ..write(obj.marque)
      ..writeByte(3)
      ..write(obj.modele)
      ..writeByte(4)
      ..write(obj.puissanceNominale)
      ..writeByte(5)
      ..write(obj.debit)
      ..writeByte(6)
      ..write(obj.hmt)
      ..writeByte(7)
      ..write(obj.rendementInitialPompe)
      ..writeByte(8)
      ..write(obj.rendementInitialMoteur)
      ..writeByte(9)
      ..write(obj.anneeInstallation)
      ..writeByte(10)
      ..write(obj.heuresFonctionnement)
      ..writeByte(11)
      ..write(obj.coutInvestissement)
      ..writeByte(12)
      ..write(obj.p1Estimee);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegacyPompeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
