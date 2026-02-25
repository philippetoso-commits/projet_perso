// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WordProgressAdapter extends TypeAdapter<WordProgress> {
  @override
  final int typeId = 2;

  @override
  WordProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WordProgress(
      profileKey: fields[0] as int,
      wordKey: fields[1] as int,
      successCount: fields[2] as int,
      failCount: fields[3] as int,
      lastSeen: fields[4] as DateTime,
      nextReview: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WordProgress obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.profileKey)
      ..writeByte(1)
      ..write(obj.wordKey)
      ..writeByte(2)
      ..write(obj.successCount)
      ..writeByte(3)
      ..write(obj.failCount)
      ..writeByte(4)
      ..write(obj.lastSeen)
      ..writeByte(5)
      ..write(obj.nextReview);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
