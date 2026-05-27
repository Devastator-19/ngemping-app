import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'my_cards_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    if (!auth.isAuthenticated) {
      return _GuestView();
    }

    return _AuthenticatedView(auth: auth);
  }
}

// ---------------------------------------------------------------------------
// Guest view — belum login
// ---------------------------------------------------------------------------

class _GuestView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryPastel, width: 2),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 40,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Belum Masuk',
                  style: GoogleFonts.comfortaa(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk untuk melihat profil, kartu anggota, dan riwayat eventmu.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text('Masuk / Daftar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Authenticated view — sudah login
// ---------------------------------------------------------------------------

class _AuthenticatedView extends StatelessWidget {
  final AppAuthProvider auth;
  const _AuthenticatedView({required this.auth});

  @override
  Widget build(BuildContext context) {
    final user = auth.user!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar
          SliverAppBar(
            backgroundColor: AppColors.background,
            floating: true,
            snap: true,
            title: Text(
              'Profil',
              style: GoogleFonts.comfortaa(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const EditProfileScreen()),
                ),
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                tooltip: 'Edit Profil',
              ),
              IconButton(
                onPressed: () => _confirmSignOut(context),
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                tooltip: 'Keluar',
              ),
              const SizedBox(width: 4),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Profile header
                _ProfileHeader(user: user),
                const SizedBox(height: 24),

                // Kartu Digital
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _DigitalCardBanner(),
                ),
                const SizedBox(height: 16),

                // Linked accounts section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _LinkedAccountsCard(auth: auth),
                ),
                const SizedBox(height: 16),

                // Account info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _AccountInfoCard(user: user),
                ),
                const SizedBox(height: 16),

                // Deletion section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _DeletionCard(auth: auth),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Keluar?',
          style: GoogleFonts.comfortaa(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Kamu akan keluar dari akun ini.',
          style: GoogleFonts.nunito(color: AppColors.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal',
                style: GoogleFonts.nunito(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await context.read<AppAuthProvider>().signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                Text('Keluar', style: GoogleFonts.nunito(color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Digital card banner
// ---------------------------------------------------------------------------

class _DigitalCardBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MyCardsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kartu Digital Anggota',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Lihat kartu keanggotaan komunitasmu',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile header — avatar + nama + member ID
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A3D2B), Color(0xFF4A7C59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.white.withValues(alpha: 0.4), width: 2.5),
            ),
            child: ClipOval(
              child: user.photoURL != null
                  ? Image.network(user.photoURL!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _InitialsCircle(user: user))
                  : _InitialsCircle(user: user),
            ),
          ),
          const SizedBox(height: 12),

          // Name
          Text(
            user.displayName ?? 'Petualang',
            style: GoogleFonts.comfortaa(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),

          // Member ID chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              user.memberId,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppColors.white.withValues(alpha: 0.85),
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  final dynamic user;
  const _InitialsCircle({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          user.initials,
          style: GoogleFonts.comfortaa(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Linked accounts card — inti dari fitur ini
// ---------------------------------------------------------------------------

class _LinkedAccountsCard extends StatelessWidget {
  final AppAuthProvider auth;
  const _LinkedAccountsCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryPastel),
            ),
            child: const Center(
              child: Icon(Icons.phone_iphone_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nomor HP',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  auth.user?.phoneNumber ?? '-',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Aktif',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account info card
// ---------------------------------------------------------------------------

class _AccountInfoCard extends StatelessWidget {
  final dynamic user;
  const _AccountInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Informasi Akun',
                style: GoogleFonts.comfortaa(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (user.email != null) ...[
            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email!),
            const SizedBox(height: 10),
          ],
          if (user.phoneNumber != null) ...[
            _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Nomor HP',
                value: user.phoneNumber!),
            const SizedBox(height: 10),
          ],
          if (user.gender != null) ...[
            _InfoRow(
                icon: Icons.wc_outlined,
                label: 'Jenis Kelamin',
                value: user.gender!),
            const SizedBox(height: 10),
          ],
          if (user.provinsi != null) ...[
            _InfoRow(
                icon: Icons.map_outlined,
                label: 'Provinsi',
                value: user.provinsi!),
            const SizedBox(height: 10),
          ],
          if (user.district != null) ...[
            _InfoRow(
                icon: Icons.location_city_outlined,
                label: 'Kota / Kabupaten',
                value: user.district!),
            const SizedBox(height: 10),
          ],
          if (user.alamat != null) ...[
            _InfoRow(
                icon: Icons.home_outlined,
                label: 'Alamat',
                value: user.alamat!),
            const SizedBox(height: 10),
          ],
          _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Member ID',
              value: user.memberId),
          if (user.createdAt != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Bergabung',
              value:
                  '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}',
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textLight),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 11, color: AppColors.textLight)),
            Text(value,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Deletion card — request / cancel account deletion
// ---------------------------------------------------------------------------

class _DeletionCard extends StatelessWidget {
  final AppAuthProvider auth;
  const _DeletionCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    final requested = auth.deletionRequestedAt;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: requested != null
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.divider,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: requested != null
          ? _PendingDeletion(auth: auth, requestedAt: requested)
          : _RequestDeletion(auth: auth),
    );
  }
}

class _RequestDeletion extends StatelessWidget {
  final AppAuthProvider auth;
  const _RequestDeletion({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Hapus Akun',
              style: GoogleFonts.comfortaa(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Setelah permintaan dikirim, akunmu akan dihapus permanen dalam 30 hari. Kamu masih bisa membatalkan selama masa tenggang.',
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: AppColors.textMedium,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: auth.isLoading ? null : () => _confirm(context),
            icon: const Icon(Icons.delete_forever_rounded,
                size: 18, color: AppColors.error),
            label: Text(
              'Minta Penghapusan Akun',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _confirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Akun?',
            style: GoogleFonts.comfortaa(fontWeight: FontWeight.bold)),
        content: Text(
          'Akunmu akan masuk masa tenggang 30 hari sebelum dihapus permanen. Seluruh data, membership, dan riwayat event akan ikut terhapus.',
          style: GoogleFonts.nunito(
              fontSize: 13, color: AppColors.textMedium, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal',
                style: GoogleFonts.nunito(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final ok = await context.read<AppAuthProvider>().requestDeletion();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  ok
                      ? 'Permintaan penghapusan dikirim. Akun akan dihapus dalam 30 hari.'
                      : 'Gagal mengirim permintaan. Coba lagi.',
                  style: GoogleFonts.nunito(),
                ),
                backgroundColor: ok ? AppColors.primaryDark : AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Ya, Hapus Akun',
                style: GoogleFonts.nunito(color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}

class _PendingDeletion extends StatelessWidget {
  final AppAuthProvider auth;
  final DateTime requestedAt;
  const _PendingDeletion({required this.auth, required this.requestedAt});

  @override
  Widget build(BuildContext context) {
    final deleteOn = requestedAt.add(const Duration(days: 30));
    final daysLeft = deleteOn.difference(DateTime.now()).inDays + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Penghapusan Dijadwalkan',
              style: GoogleFonts.comfortaa(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Akun akan dihapus dalam $daysLeft hari',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tanggal: ${deleteOn.day}/${deleteOn.month}/${deleteOn.year}',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.error.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Seluruh data, membership, dan riwayat event akan dihapus permanen. Batalkan sekarang jika berubah pikiran.',
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: AppColors.textMedium,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: auth.isLoading ? null : () => _cancel(context),
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: Text(
              'Batalkan Penghapusan',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _cancel(BuildContext context) async {
    final ok = await context.read<AppAuthProvider>().cancelDeletion();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        ok ? 'Penghapusan akun dibatalkan.' : 'Gagal membatalkan. Coba lagi.',
        style: GoogleFonts.nunito(),
      ),
      backgroundColor: ok ? AppColors.primaryDark : AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

