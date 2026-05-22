import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EventAdditional {
  final String name;
  final double price;

  const EventAdditional({required this.name, required this.price});

  factory EventAdditional.fromJson(Map<String, dynamic> json) {
    return EventAdditional(
      name: json['name'] as String,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
    );
  }
}

class EventModel {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final String? mapsUrl;
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double price;
  final int pricePerPax;
  final List<EventAdditional> additionals;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final int? maxParticipants;
  final String? coverImageUrl;
  final String? accentColorHex;
  final int registrationCount;
  // null = not registered, 'REGISTERED', 'WAITING_PAYMENT', 'CANCELLED'
  final String? myRegistrationStatus;

  const EventModel({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.mapsUrl,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.price,
    this.pricePerPax = 1,
    this.additionals = const [],
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.maxParticipants,
    this.coverImageUrl,
    this.accentColorHex,
    required this.registrationCount,
    this.myRegistrationStatus,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map<String, dynamic>?;
    final rawAdditionals = json['additionals'] as List<dynamic>?;
    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      mapsUrl: json['mapsUrl'] as String?,
      category: json['category'] as String? ?? 'OTHER',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: json['status'] as String? ?? 'OPEN',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      pricePerPax: json['pricePerPax'] as int? ?? 1,
      additionals: rawAdditionals
          ?.map((e) => EventAdditional.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      bankName: json['bankName'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankAccountName: json['bankAccountName'] as String?,
      maxParticipants: json['maxParticipants'] as int?,
      coverImageUrl: json['coverImageUrl'] as String?,
      accentColorHex: json['accentColorHex'] as String?,
      registrationCount: count?['registrations'] as int? ?? 0,
      myRegistrationStatus: json['myRegistrationStatus'] as String?,
    );
  }

  Color get accentColor {
    if (accentColorHex != null && accentColorHex!.isNotEmpty) {
      try {
        return Color(int.parse(accentColorHex!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    switch (category) {
      case 'CAMPING':
        return AppColors.primary;
      case 'HIKING':
        return AppColors.secondary;
      case 'TREKKING':
        return const Color(0xFF8B6914);
      case 'FAMILY':
        return const Color(0xFF5B8DB8);
      default:
        return AppColors.primary;
    }
  }

  String get categoryLabel {
    switch (category) {
      case 'CAMPING':
        return 'Camping';
      case 'HIKING':
        return 'Hiking';
      case 'TREKKING':
        return 'Trekking';
      case 'FAMILY':
        return 'Family';
      default:
        return 'Lainnya';
    }
  }

  String get formattedDate {
    final start = _fmt(startDate);
    final end = _fmt(endDate);
    if (start == end) return start;
    if (startDate.month == endDate.month && startDate.year == endDate.year) {
      return '${startDate.day}–${endDate.day} ${_monthShort(startDate.month)} ${startDate.year}';
    }
    return '$start – $end';
  }

  static String _monthShort(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[m - 1];
  }

  static String _fmt(DateTime d) => '${d.day} ${_monthShort(d.month)} ${d.year}';
}
