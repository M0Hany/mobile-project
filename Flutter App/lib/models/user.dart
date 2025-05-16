import 'dart:convert';
import 'dart:typed_data';

class User {
  final String email;
  final String name;
  final String? gender;
  final int? level;
  final String? profilePicture;
  final Uint8List? profilePictureData;
  final String? password;

  User({
    required this.email,
    required this.name,
    this.gender,
    this.level,
    this.profilePicture,
    this.profilePictureData,
    this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'gender': gender,
      'level': level,
      'profile_picture': profilePicture,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      email: map['email'],
      name: map['name'],
      gender: map['gender'],
      level: map['level'] != null ? int.parse(map['level'].toString()) : null,
      profilePicture: map['profile_picture'],
      password: map['password'],
    );
  }

  User copyWith({
    String? email,
    String? name,
    String? gender,
    int? level,
    String? profilePicture,
    Uint8List? profilePictureData,
    String? password,
  }) {
    return User(
      email: email ?? this.email,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      level: level ?? this.level,
      profilePicture: profilePicture ?? this.profilePicture,
      profilePictureData: profilePictureData ?? this.profilePictureData,
      password: password ?? this.password,
    );
  }
}
