// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      name: fields[0] as String,
      email: fields[2] as String,
      studentId: fields[3] as String,
      password: fields[5] as String,
      level: fields[4] == null ? '' : fields[4] as String,
      gender: fields[1] == null ? '' : fields[1] as String,
      profilePicture: fields[6] as Uint8List?,
      favoriteStores:
          fields[7] == null ? [] : (fields[7] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.gender)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.studentId)
      ..writeByte(4)
      ..write(obj.level)
      ..writeByte(5)
      ..write(obj.password)
      ..writeByte(6)
      ..write(obj.profilePicture)
      ..writeByte(7)
      ..write(obj.favoriteStores);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
