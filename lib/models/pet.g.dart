// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PetModelAdapter extends TypeAdapter<PetModel> {
  @override
  final int typeId = 4;

  @override
  PetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PetModel(
      id: fields[0] as String,
      name: fields[1] as String,
      species: fields[2] as String,
      stage: fields[3] as String,
      level: fields[4] as int,
      exp: fields[5] as int,
      hp: fields[6] as int,
      hunger: fields[7] as int,
      mood: fields[8] as int,
      dirty: fields[9] as int,
      stamina: fields[10] as int,
      intimacy: fields[11] as int,
      genreStats: (fields[12] as Map).cast<String, int>(),
      birthDate: fields[13] as DateTime,
      lastFed: fields[14] as DateTime,
      lastPlayed: fields[15] as DateTime,
      lastCleaned: fields[16] as DateTime,
      age: fields[17] as int,
      isAlive: fields[18] as bool,
      isSick: fields[19] as bool,
      sickness: fields[20] as String?,
      skills: (fields[21] as List).cast<String>(),
      attack: fields[22] as int,
      defense: fields[23] as int,
      speed: fields[24] as int,
      wins: fields[25] as int,
      losses: fields[26] as int,
      playCount: fields[27] as int,
      cleanCount: fields[28] as int,
      battleCount: fields[29] as int,
      evolutionProgress: (fields[30] as Map).cast<String, dynamic>(),
      isActive: fields[31] as bool,
      lastHealthCheck: fields[32] as DateTime?,
      personality: fields[33] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PetModel obj) {
    writer
      ..writeByte(34)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.species)
      ..writeByte(3)
      ..write(obj.stage)
      ..writeByte(4)
      ..write(obj.level)
      ..writeByte(5)
      ..write(obj.exp)
      ..writeByte(6)
      ..write(obj.hp)
      ..writeByte(7)
      ..write(obj.hunger)
      ..writeByte(8)
      ..write(obj.mood)
      ..writeByte(9)
      ..write(obj.dirty)
      ..writeByte(10)
      ..write(obj.stamina)
      ..writeByte(11)
      ..write(obj.intimacy)
      ..writeByte(12)
      ..write(obj.genreStats)
      ..writeByte(13)
      ..write(obj.birthDate)
      ..writeByte(14)
      ..write(obj.lastFed)
      ..writeByte(15)
      ..write(obj.lastPlayed)
      ..writeByte(16)
      ..write(obj.lastCleaned)
      ..writeByte(17)
      ..write(obj.age)
      ..writeByte(18)
      ..write(obj.isAlive)
      ..writeByte(19)
      ..write(obj.isSick)
      ..writeByte(20)
      ..write(obj.sickness)
      ..writeByte(21)
      ..write(obj.skills)
      ..writeByte(22)
      ..write(obj.attack)
      ..writeByte(23)
      ..write(obj.defense)
      ..writeByte(24)
      ..write(obj.speed)
      ..writeByte(25)
      ..write(obj.wins)
      ..writeByte(26)
      ..write(obj.losses)
      ..writeByte(27)
      ..write(obj.playCount)
      ..writeByte(28)
      ..write(obj.cleanCount)
      ..writeByte(29)
      ..write(obj.battleCount)
      ..writeByte(30)
      ..write(obj.evolutionProgress)
      ..writeByte(31)
      ..write(obj.isActive)
      ..writeByte(32)
      ..write(obj.lastHealthCheck)
      ..writeByte(33)
      ..write(obj.personality);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
