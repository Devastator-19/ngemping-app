import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/community_model.dart';
import '../auth/providers/auth_provider.dart';
import 'providers/community_detail_provider.dart';
import 'providers/community_provider.dart';
import 'member_card_screen.dart';
import 'widgets/join_community_sheet.dart';

class CommunityDetailScreen extends StatelessWidget {
  final CommunityModel community;

  const CommunityDetailScreen({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommunityDetailProvider(communityId: community.id)..fetchAll(),
      child: _CommunityDetailView(initialCommunity: community),
    );
  }
}

// ---------------------------------------------------------------------------
// Main view with SliverAppBar + TabBar
// ---------------------------------------------------------------------------

class _CommunityDetailView extends StatefulWidget {
  final CommunityModel initialCommunity;
  const _CommunityDetailView({required this.initialCommunity});

  @override
  State<_CommunityDetailView> createState() => _CommunityDetailViewState();
}

class _CommunityDetailViewState extends State<_CommunityDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late bool _isAuthenticated;

  @override
  void initState() {
    super.initState();
    _isAuthenticated = context.read<AppAuthProvider>().isAuthenticated;
    _tab = TabController(length: _isAuthenticated ? 5 : 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityDetailProvider>();
    final auth = context.watch<AppAuthProvider>();
    final community = provider.community ?? widget.initialCommunity;

    final myMember = provider.members
        .where((m) => m.userId == auth.user?.uid && m.status == 'ACTIVE')
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          _CommunityAppBar(
            community: community,
            provider: provider,
            myMember: myMember,
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tab,
                labelStyle: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle:
                    GoogleFonts.nunito(fontWeight: FontWeight.w500, fontSize: 13),
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textLight,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                tabs: [
                  const Tab(text: 'Tentang'),
                  const Tab(text: 'Organisasi'),
                  if (_isAuthenticated) const Tab(text: 'Event'),
                  const Tab(text: 'Anggota'),
                  const Tab(text: 'Sosmed'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _TentangTab(community: community),
            _OrganisasiTab(provider: provider),
            if (_isAuthenticated) _EventTab(provider: provider),
            _AnggotaTab(provider: provider),
            _SosmedTab(community: community),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sliver AppBar with banner + community info + join button
// ---------------------------------------------------------------------------

class _CommunityAppBar extends StatelessWidget {
  final CommunityModel community;
  final CommunityDetailProvider provider;
  final CommunityMemberModel? myMember;

  const _CommunityAppBar({
    required this.community,
    required this.provider,
    this.myMember,
  });

  bool get _hasCard {
    final cfg = community.cardConfig;
    if (cfg == null) return false;
    final bg = cfg['backgroundUrl'] as String? ?? '';
    return bg.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final isLoggedIn = auth.isAuthenticated;

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: myMember != null && _hasCard
          ? [
              IconButton(
                tooltip: 'Kartu Anggota',
                icon: const Icon(Icons.credit_card_outlined, color: AppColors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MemberCardScreen(
                      cardConfig: community.cardConfig!,
                      memberName: myMember!.displayName ?? 'Anggota',
                      communityMemberId: myMember!.communityMemberId,
                      memberPhotoUrl: myMember!.photoUrl,
                      communityName: community.name,
                      communityLogoUrl: community.logoUrl,
                    ),
                  ),
                ),
              ),
            ]
          : null,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner
            community.bannerUrl != null
                ? Image.network(community.bannerUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _GradientBanner())
                : _GradientBanner(),
            // Overlay gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.primaryDark.withValues(alpha: 0.85),
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
            // Community info
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.3)),
                    ),
                    child: community.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.network(community.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.cabin_rounded,
                                        color: AppColors.white, size: 28)),
                          )
                        : const Icon(Icons.cabin_rounded,
                            color: AppColors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  // Name + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          community.name,
                          style: GoogleFonts.comfortaa(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.people_outline_rounded,
                                size: 13, color: AppColors.primaryPastel),
                            const SizedBox(width: 4),
                            Text(
                              '${community.memberCount} anggota',
                              style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: AppColors.primaryPastel),
                            ),
                            if (community.location != null) ...[
                              const SizedBox(width: 10),
                              const Icon(Icons.location_on_outlined,
                                  size: 13, color: AppColors.primaryPastel),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  community.location!,
                                  style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: AppColors.primaryPastel),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Join/Leave button
                  if (isLoggedIn)
                    _JoinButton(community: community, provider: provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A3D2B), Color(0xFF4A7C59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  final CommunityModel community;
  final CommunityDetailProvider provider;

  const _JoinButton({required this.community, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isJoined = community.isJoined;
    final isPending = community.isPending;
    final isLoading = provider.isJoining;

    if (isLoading) {
      return Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(8),
        child: const CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.white),
      );
    }

    if (isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.secondaryLight.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.secondaryLight.withValues(alpha: 0.6)),
        ),
        child: Text(
          'Menunggu',
          style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryLight),
        ),
      );
    }

    if (isJoined) {
      return GestureDetector(
        onTap: () => _confirmLeave(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.4)),
          ),
          child: Text(
            'Bergabung',
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.white),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _join(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          community.isPublic ? 'Gabung' : 'Minta Gabung',
          style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark),
        ),
      ),
    );
  }

  Future<void> _join(BuildContext context) async {
    final community = provider.community;
    if (community == null) return;

    final msg = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JoinCommunitySheet(community: community),
    );

    if (!context.mounted) return;
    if (msg != null) {
      // Refresh detail + sync list
      provider.fetchDetail();
      context.read<CommunityProvider>().fetchCommunities();
      ScaffoldMessenger.of(context).showSnackBar(_snack(msg, true));
    }
  }

  void _confirmLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Keluar dari komunitas?',
            style: GoogleFonts.comfortaa(fontWeight: FontWeight.bold)),
        content: Text(
          'Kamu akan meninggalkan ${provider.community?.name ?? 'komunitas ini'}.',
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
              await provider.leaveCommunity();
              if (!context.mounted) return;
              context.read<CommunityProvider>().fetchCommunities();
              context.read<CommunityProvider>().fetchMyCommunities();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Keluar',
                style: GoogleFonts.nunito(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  SnackBar _snack(String msg, bool ok) => SnackBar(
        content: Text(msg, style: GoogleFonts.nunito()),
        backgroundColor: ok ? AppColors.primaryDark : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      );
}

// ---------------------------------------------------------------------------
// Tab: Tentang
// ---------------------------------------------------------------------------

class _TentangTab extends StatelessWidget {
  final CommunityModel community;
  const _TentangTab({required this.community});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (community.description != null && community.description!.isNotEmpty) ...[
          _SectionTitle('Deskripsi'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              community.description!,
              style: GoogleFonts.nunito(
                  fontSize: 14, color: AppColors.textMedium, height: 1.6),
            ),
          ),
          const SizedBox(height: 20),
        ],
        _SectionTitle('Informasi'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.people_alt_outlined,
                label: 'Total Anggota',
                value: '${community.memberCount} orang',
              ),
              _Divider(),
              _InfoTile(
                icon: Icons.location_on_outlined,
                label: 'Lokasi',
                value: community.location ?? '-',
              ),
              _Divider(),
              _InfoTile(
                icon: community.isPublic
                    ? Icons.lock_open_outlined
                    : Icons.lock_outline_rounded,
                label: 'Tipe Komunitas',
                value: community.isPublic ? 'Publik' : 'Privat',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab: Organisasi
// ---------------------------------------------------------------------------

class _OrganisasiTab extends StatelessWidget {
  final CommunityDetailProvider provider;
  const _OrganisasiTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.loadingOrg && provider.orgPositions.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final positions = provider.orgPositions;
    final memberCount = provider.community?.memberCount ?? 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people_alt_outlined,
                label: 'Total Anggota',
                value: '$memberCount',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.account_tree_outlined,
                label: 'Jabatan',
                value: '${positions.length}',
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (positions.isEmpty)
          _EmptyState(
            icon: Icons.groups_outlined,
            message: 'Belum ada struktur organisasi.',
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                for (int i = 0; i < positions.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: Colors.grey.shade50),
                  _OrgPositionTile(position: positions[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _OrgPositionTile extends StatelessWidget {
  final OrgPositionModel position;
  const _OrgPositionTile({required this.position});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                ),
                if (position.members.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: position.members.map((m) => _MemberChip(member: m)).toList(),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text('Kosong', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final OrgMember member;
  const _MemberChip({required this.member});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: const Color(0xFFEDF4ED),
          backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
          child: member.photoUrl == null
              ? Text(member.initials, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary))
              : null,
        ),
        const SizedBox(width: 5),
        Text(
          member.displayName ?? '-',
          style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab: Event
// ---------------------------------------------------------------------------

class _EventTab extends StatelessWidget {
  final CommunityDetailProvider provider;
  const _EventTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.loadingEvents && provider.events.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final openEvents = provider.events.where((e) => e.status == 'OPEN').toList();

    if (openEvents.isEmpty) {
      return _EmptyState(
        icon: Icons.event_outlined,
        message: provider.events.isEmpty
            ? 'Belum ada event dari komunitas ini.'
            : 'Tidak ada event yang sedang membuka pendaftaran.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: openEvents.length + (provider.hasMoreEvents ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i == openEvents.length) {
          return _LoadMoreButton(
            isLoading: provider.loadingEvents,
            onTap: () => provider.fetchEvents(),
          );
        }
        return _EventCard(event: openEvents[i]);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab: Anggota
// ---------------------------------------------------------------------------

class _AnggotaTab extends StatelessWidget {
  final CommunityDetailProvider provider;
  const _AnggotaTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.loadingMembers && provider.members.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (provider.members.isEmpty) {
      return _EmptyState(
        icon: Icons.people_outline_rounded,
        message: 'Belum ada anggota.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: provider.members.length + (provider.hasMoreMembers ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i == provider.members.length) {
          return _LoadMoreButton(
            isLoading: provider.loadingMembers,
            onTap: () => provider.fetchMembers(),
          );
        }
        return _MemberTile(member: provider.members[i], showRoleBadge: true);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab: Sosmed
// ---------------------------------------------------------------------------

class _SosmedTab extends StatelessWidget {
  final CommunityModel community;
  const _SosmedTab({required this.community});

  static const _platforms = [
    (
      key: 'instagram',
      label: 'Instagram',
      icon: Icons.photo_camera_outlined,
      color: Color(0xFFE1306C),
      buildUrl: _igUrl,
    ),
    (
      key: 'tiktok',
      label: 'TikTok',
      icon: Icons.music_note_rounded,
      color: Color(0xFF010101),
      buildUrl: _ttUrl,
    ),
    (
      key: 'facebook',
      label: 'Facebook',
      icon: Icons.facebook_rounded,
      color: Color(0xFF1877F2),
      buildUrl: _fbUrl,
    ),
    (
      key: 'youtube',
      label: 'YouTube',
      icon: Icons.play_circle_outline_rounded,
      color: Color(0xFFFF0000),
      buildUrl: _ytUrl,
    ),
    (
      key: 'whatsapp',
      label: 'WhatsApp',
      icon: Icons.chat_bubble_outline_rounded,
      color: Color(0xFF25D366),
      buildUrl: _waUrl,
    ),
    (
      key: 'website',
      label: 'Website',
      icon: Icons.language_rounded,
      color: AppColors.primary,
      buildUrl: _webUrl,
    ),
  ];

  static String _igUrl(String v) {
    final handle = v.replaceFirst(RegExp(r'^@'), '');
    return 'https://instagram.com/$handle';
  }

  static String _ttUrl(String v) {
    final handle = v.startsWith('@') ? v : '@$v';
    return 'https://tiktok.com/$handle';
  }

  static String _fbUrl(String v) =>
      v.startsWith('http') ? v : 'https://facebook.com/$v';

  static String _ytUrl(String v) =>
      v.startsWith('http') ? v : 'https://youtube.com/$v';

  static String _waUrl(String v) {
    final digits = v.replaceAll(RegExp(r'[^\d]'), '');
    return 'https://wa.me/$digits';
  }

  static String _webUrl(String v) =>
      v.startsWith('http') ? v : 'https://$v';

  String? _getValue(String key) {
    final sm = community.socialMedia;
    if (sm == null) return null;
    switch (key) {
      case 'instagram': return sm.instagram;
      case 'tiktok':    return sm.tiktok;
      case 'facebook':  return sm.facebook;
      case 'youtube':   return sm.youtube;
      case 'whatsapp':  return sm.whatsapp;
      case 'website':   return sm.website;
      default:          return null;
    }
  }

  Future<void> _open(BuildContext context, String url, String label) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak bisa membuka $label', style: GoogleFonts.nunito(fontSize: 13)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppColors.textDark,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sm = community.socialMedia;
    final hasAny = sm != null && !sm.isEmpty;

    if (!hasAny) {
      return _EmptyState(
        icon: Icons.link_off_rounded,
        message: 'Belum ada akun sosial media yang terdaftar.',
      );
    }

    final available = _platforms
        .where((p) => _getValue(p.key) != null)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              for (int i = 0; i < available.length; i++) ...[
                if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.divider, indent: 16, endIndent: 16),
                _SosmedTile(
                  platform: available[i],
                  value: _getValue(available[i].key)!,
                  onTap: () => _open(
                    context,
                    available[i].buildUrl(_getValue(available[i].key)!),
                    available[i].label,
                  ),
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: _getValue(available[i].key)!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${available[i].label} disalin', style: GoogleFonts.nunito(fontSize: 13)),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tekan lama untuk menyalin',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textLight),
        ),
      ],
    );
  }
}

class _SosmedTile extends StatelessWidget {
  final ({String key, String label, IconData icon, Color color, String Function(String) buildUrl}) platform;
  final String value;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SosmedTile({
    required this.platform,
    required this.value,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: platform.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(platform.icon, color: platform.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform.label,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.comfortaa(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 11, color: AppColors.textLight)),
              Text(value,
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1, thickness: 1, color: AppColors.divider, indent: 16, endIndent: 16);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.comfortaa(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final CommunityMemberModel member;
  final bool showRoleBadge;
  const _MemberTile({required this.member, this.showRoleBadge = false});

  @override
  Widget build(BuildContext context) {
    final isOwner = member.role == 'OWNER';
    final isAdmin = member.role == 'ADMIN';
    final badgeColor = isOwner
        ? AppColors.secondary
        : isAdmin
            ? AppColors.primary
            : AppColors.textLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Avatar
          _MemberAvatar(member: member),
          const SizedBox(width: 12),
          // Name + member ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName ?? 'Anggota',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (member.memberId != null)
                  Text(
                    member.memberId!,
                    style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: AppColors.textLight,
                        letterSpacing: 0.5),
                  ),
              ],
            ),
          ),
          // Role badge
          if (showRoleBadge && member.role != 'MEMBER')
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: badgeColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                member.roleLabel,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final CommunityMemberModel member;
  const _MemberAvatar({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipOval(
        child: member.photoUrl != null
            ? Image.network(member.photoUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _InitialsAvatar(member: member))
            : _InitialsAvatar(member: member),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final CommunityMemberModel member;
  const _InitialsAvatar({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primarySurface,
      child: Center(
        child: Text(
          member.initials,
          style: GoogleFonts.comfortaa(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CommunityEventModel event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dateStr =
        '${event.startDate.day} ${months[event.startDate.month - 1]} ${event.startDate.year}';

    Color accentColor = AppColors.primary;
    if (event.accentColorHex != null && event.accentColorHex!.isNotEmpty) {
      try {
        accentColor = Color(
            int.parse('FF${event.accentColorHex!.replaceAll('#', '')}',
                radix: 16));
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Date accent strip
          Container(
            width: 6,
            color: accentColor,
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: GoogleFonts.comfortaa(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: event.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MetaChip(
                          icon: Icons.calendar_today_outlined,
                          label: dateStr),
                      const SizedBox(width: 8),
                      if (event.location != null)
                        Flexible(
                          child: _MetaChip(
                              icon: Icons.location_on_outlined,
                              label: event.location!),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MetaChip(
                        icon: Icons.people_outline_rounded,
                        label: event.maxParticipants != null
                            ? '${event.registrantCount}/${event.maxParticipants}'
                            : '${event.registrantCount} peserta',
                      ),
                      const Spacer(),
                      Text(
                        event.isFree
                            ? 'Gratis'
                            : 'Rp ${_formatPrice(event.price)}',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: event.isFree
                              ? AppColors.primary
                              : AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}jt';
    }
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}rb';
    }
    return price.toStringAsFixed(0);
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'OPEN':
        color = AppColors.primary;
        label = 'Buka';
        break;
      case 'FULL':
        color = AppColors.error;
        label = 'Penuh';
        break;
      case 'CLOSED':
        color = AppColors.textLight;
        label = 'Tutup';
        break;
      default:
        color = AppColors.textLight;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textLight),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.primaryPastel),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 14, color: AppColors.textLight, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _LoadMoreButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            )
          : TextButton(
              onPressed: onTap,
              child: Text(
                'Muat lebih banyak',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// TabBar delegate (pinned persistent header)
// ---------------------------------------------------------------------------

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
