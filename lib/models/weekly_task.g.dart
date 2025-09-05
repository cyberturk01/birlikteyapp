// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeeklyTaskAdapter extends TypeAdapter<WeeklyTask> {
  @override
  final int typeId = 2;

  @override
  WeeklyTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklyTask(
      fields[0] as String,
      fields[1] as String,
      assignedTo: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyTask obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.day)
      ..writeByte(1)
      ..write(obj.task)
      ..writeByte(2)
      ..write(obj.assignedTo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
