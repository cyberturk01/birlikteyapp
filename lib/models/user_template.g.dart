// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserTemplateAdapter extends TypeAdapter<UserTemplate> {
  @override
  final int typeId = 35;

  @override
  UserTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserTemplate(
      name: fields[0] as String,
      description: fields[1] as String,
      tasks: (fields[2] as List?)?.cast<String>(),
      items: (fields[3] as List?)?.cast<String>(),
      weekly: (fields[4] as List?)?.cast<WeeklyEntry>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserTemplate obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.tasks)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.weekly);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WeeklyEntryAdapter extends TypeAdapter<WeeklyEntry> {
  @override
  final int typeId = 36;

  @override
  WeeklyEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklyEntry(
      fields[0] as String,
      fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyEntry obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.day)
      ..writeByte(1)
      ..write(obj.title);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
