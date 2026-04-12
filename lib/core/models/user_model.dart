import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final String? phoneNumber;
  final DateTime? createdAt;
  final String? alamat;
  final String? gender;
  final String? provinsi;
  final String? district;

  const UserModel({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    this.phoneNumber,
    this.createdAt,
    this.alamat,
    this.gender,
    this.provinsi,
    this.district,
  });

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoURL: user.photoURL,
      phoneNumber: user.phoneNumber,
      createdAt: user.metadata.creationTime,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json, {required String uid}) {
    return UserModel(
      uid: uid,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      photoURL: json['photoURL'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      alamat: json['alamat'] as String?,
      gender: json['gender'] as String?,
      provinsi: json['provinsi'] as String?,
      district: json['district'] as String?,
    );
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    String? phoneNumber,
    DateTime? createdAt,
    String? alamat,
    String? gender,
    String? provinsi,
    String? district,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      alamat: alamat ?? this.alamat,
      gender: gender ?? this.gender,
      provinsi: provinsi ?? this.provinsi,
      district: district ?? this.district,
    );
  }

  /// Member ID formatted: JAI-2026-XXXX (4 chars from uid)
  String get memberId {
    final shortUid = uid.substring(0, 4).toUpperCase();
    final year = (createdAt ?? DateTime.now()).year;
    return 'JAI-$year-$shortUid';
  }

  String get firstName {
    if (displayName == null || displayName!.isEmpty) return 'Petualang';
    return displayName!.split(' ').first;
  }

  String get initials {
    if (displayName == null || displayName!.isEmpty) return 'P';
    final parts = displayName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
