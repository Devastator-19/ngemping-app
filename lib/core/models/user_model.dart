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
  final String? nickName;
  final String? placeOfBirth;
  final DateTime? dateOfBirth;

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
    this.nickName,
    this.placeOfBirth,
    this.dateOfBirth,
  });

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
    String? nickName,
    String? placeOfBirth,
    DateTime? dateOfBirth,
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
      nickName: nickName ?? this.nickName,
      placeOfBirth: placeOfBirth ?? this.placeOfBirth,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }

  String get memberId {
    final shortUid = uid.length >= 4 ? uid.substring(0, 4).toUpperCase() : uid.toUpperCase();
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
