// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WordAdapter extends TypeAdapter<Word> {
  @override
  final int typeId = 0;

  @override
  Word read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Word(
      text: fields[0] as String,
      syllables: (fields[1] as List).cast<String>(),
      theme: fields[2] as String,
      imagePath: fields[3] as String,
      level: fields[4] as int,
      lastSeen: fields[5] as DateTime,
      nextReview: fields[6] as DateTime,
      successCount: fields[7] as int,
      failedPhonemes: (fields[8] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Word obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.syllables)
      ..writeByte(2)
      ..write(obj.theme)
      ..writeByte(3)
      ..write(obj.imagePath)
      ..writeByte(4)
      ..write(obj.level)
      ..writeByte(5)
      ..write(obj.lastSeen)
      ..writeByte(6)
      ..write(obj.nextReview)
      ..writeByte(7)
      ..write(obj.successCount)
      ..writeByte(8)
      ..write(obj.failedPhonemes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
