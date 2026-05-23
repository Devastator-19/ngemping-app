import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import 'providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<NotificationProvider>().loadNotifications(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Notifikasi',
          style: GoogleFonts.comfortaa(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, provider, __) {
              if (provider.unreadCount == 0) return const SizedBox();
              return TextButton(
                onPressed: provider.isLoading ? null : () => provider.markAllAsRead(),
                child: Text(
                  'Tandai semua dibaca',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: AppColors.textLight),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada notifikasi',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.loadNotifications(refresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, i) {
                final notif = provider.notifications[i];
                return _NotificationTile(
                  notif: notif,
                  onTap: () => provider.markAsRead(notif['id']),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notif;
  final VoidCallback onTap;

  const _NotificationTile({required this.notif, required this.onTap});

  IconData _iconForType(String? type) {
    switch (type) {
      case 'COMMUNITY_ACCEPTED':
        return Icons.group_rounded;
      case 'COMMUNITY_REJECTED':
        return Icons.group_off_rounded;
      case 'EVENT_REGISTERED':
        return Icons.event_available_rounded;
      case 'EVENT_WAITING_PAYMENT':
        return Icons.payment_rounded;
      case 'EVENT_PAYMENT_REVIEWING':
        return Icons.hourglass_top_rounded;
      case 'EVENT_PAYMENT_APPROVED':
        return Icons.check_circle_rounded;
      case 'EVENT_PAYMENT_REJECTED':
        return Icons.cancel_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'COMMUNITY_ACCEPTED':
      case 'EVENT_REGISTERED':
      case 'EVENT_PAYMENT_APPROVED':
        return AppColors.primary;
      case 'COMMUNITY_REJECTED':
      case 'EVENT_PAYMENT_REJECTED':
        return Colors.red;
      case 'EVENT_WAITING_PAYMENT':
        return Colors.orange;
      case 'EVENT_PAYMENT_REVIEWING':
        return Colors.blue;
      default:
        return AppColors.textMedium;
    }
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notif['isRead'] == true;
    final type = notif['type'] as String?;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead ? Colors.transparent : AppColors.primarySurface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _colorForType(type).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconForType(type), color: _colorForType(type), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif['title'] ?? '',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notif['body'] ?? '',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.textMedium,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notif['createdAt'] as String?),
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
