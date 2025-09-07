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
      fields[1] as String,
      fields[0] as String,
      assignedTo: fields[2] as String?,
      hour: fields[3] as int?,
      minute: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyTask obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.day)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.assignedTo)
      ..writeByte(3)
      ..write(obj.hour)
      ..writeByte(4)
      ..write(obj.minute);
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
