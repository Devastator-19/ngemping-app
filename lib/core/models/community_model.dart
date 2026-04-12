class CommunityModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? location;
  final bool isPublic;
  final int memberCount;
  final String? membershipStatus; // null = belum join

  const CommunityModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.location,
    required this.isPublic,
    required this.memberCount,
    this.membershipStatus,
  });

  bool get isJoined => membershipStatus == 'ACTIVE';
  bool get isPending => membershipStatus == 'PENDING';

  CommunityModel copyWith({String? membershipStatus}) {
    return CommunityModel(
      id: id,
      name: name,
      slug: slug,
      description: description,
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
      location: location,
      isPublic: isPublic,
      memberCount: memberCount,
      membershipStatus: membershipStatus ?? this.membershipStatus,
    );
  }

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      location: json['location'] as String?,
      isPublic: json['isPublic'] as bool? ?? true,
      memberCount: (json['_count'] as Map<String, dynamic>?)?['members'] as int? ?? 0,
      membershipStatus: json['membershipStatus'] as String?,
    );
  }
}

class CommunityMemberModel {
  final String id;
  final String role;
  final String status;
  final DateTime joinedAt;
  final String userId;
  final String? displayName;
  final String? photoUrl;
  final String? memberId;

  const CommunityMemberModel({
    required this.id,
    required this.role,
    required this.status,
    required this.joinedAt,
    required this.userId,
    this.displayName,
    this.photoUrl,
    this.memberId,
  });

  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return CommunityMemberModel(
      id: json['id'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      userId: user['id'] as String? ?? '',
      displayName: user['displayName'] as String?,
      photoUrl: user['photoUrl'] as String?,
      memberId: user['memberId'] as String?,
    );
  }

  String get roleLabel {
    switch (role) {
      case 'OWNER':
        return 'Ketua';
      case 'ADMIN':
        return 'Pengurus';
      default:
        return 'Anggota';
    }
  }

  String get initials {
    if (displayName == null || displayName!.isEmpty) return 'A';
    final parts = displayName!.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}

class CommunityEventModel {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final int? maxParticipants;
  final double price;
  final String? coverImageUrl;
  final String? accentColorHex;
  final String status;
  final int registrantCount;

  const CommunityEventModel({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.category,
    required this.startDate,
    required this.endDate,
    this.maxParticipants,
    required this.price,
    this.coverImageUrl,
    this.accentColorHex,
    required this.status,
    required this.registrantCount,
  });

  factory CommunityEventModel.fromJson(Map<String, dynamic> json) {
    return CommunityEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      category: json['category'] as String? ?? 'OTHER',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      maxParticipants: json['maxParticipants'] as int?,
      price: double.tryParse(json['price'].toString()) ?? 0,
      coverImageUrl: json['coverImageUrl'] as String?,
      accentColorHex: json['accentColorHex'] as String?,
      status: json['status'] as String? ?? 'OPEN',
      registrantCount:
          (json['_count'] as Map<String, dynamic>?)?['registrations'] as int? ?? 0,
    );
  }

  bool get isFree => price == 0;
  bool get isFull => maxParticipants != null && registrantCount >= maxParticipants!;
}

class MyCommunityModel {
  final String id;
  final String role;
  final String status;
  final DateTime joinedAt;
  final CommunityModel community;

  const MyCommunityModel({
    required this.id,
    required this.role,
    required this.status,
    required this.joinedAt,
    required this.community,
  });

  factory MyCommunityModel.fromJson(Map<String, dynamic> json) {
    return MyCommunityModel(
      id: json['id'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      community: CommunityModel.fromJson(json['community'] as Map<String, dynamic>),
    );
  }
}
