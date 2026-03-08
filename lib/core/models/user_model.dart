import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final String? phoneNumber;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    this.phoneNumber,
    this.createdAt,
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
