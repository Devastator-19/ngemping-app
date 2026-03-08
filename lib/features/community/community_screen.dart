import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/community_model.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'providers/community_provider.dart';
import 'community_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  AuthStatus? _lastAuthStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    final provider = context.read<CommunityProvider>();
    final isAuth = context.read<AppAuthProvider>().isAuthenticated;
    provider.fetchCommunities();
    if (isAuth) provider.fetchMyCommunities();
  }

  // Dipanggil setiap build — reaksi saat auth status berubah
  void _onAuthChanged(AuthStatus status) {
    if (_lastAuthStatus == status) return;
    _lastAuthStatus = status;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<CommunityProvider>();
      if (status == AuthStatus.authenticated) {
        provider.fetchMyCommunities();
        provider.fetchCommunities();
      } else if (status == AuthStatus.unauthenticated) {
        provider.reset();
        provider.fetchCommunities();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final provider = context.watch<CommunityProvider>();

    _onAuthChanged(auth.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: AppColors.background,
            floating: true,
            snap: true,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            shadowColor: AppColors.divider,
            title: Text(
              'Komunitas',
              style: GoogleFonts.comfortaa(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(108),
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _SearchBar(
                      controller: _searchController,
                      onChanged: (q) =>
                          context.read<CommunityProvider>().onSearchChanged(q),
                      onClear: () {
                        _searchController.clear();
                        context.read<CommunityProvider>().clearSearch();
                      },
                    ),
                  ),
                  // Tabs
                  TabBar(
                    controller: _tabController,
                    labelStyle: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: GoogleFonts.nunito(fontSize: 13),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textLight,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: [
                      const Tab(text: 'Semua Komunitas'),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Komunitas Saya'),
                            if (auth.isAuthenticated &&
                                provider.myCommunities.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${provider.myCommunities.length}',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Semua komunitas
            _AllCommunitiesTab(
              provider: provider,
              isAuthenticated: auth.isAuthenticated,
              onRetry: _load,
              onJoin: _handleJoin,
              onLeave: _handleLeave,
            ),
            // Tab 2: Komunitas saya
            _MyCommunitiesTab(
              provider: provider,
              isAuthenticated: auth.isAuthenticated,
              onLeave: _handleLeave,
              onGoToAll: () => _tabController.animateTo(0),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleJoin(CommunityModel community) async {
    if (!context.read<AppAuthProvider>().isAuthenticated) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final msg =
        await context.read<CommunityProvider>().joinCommunity(community.id);
    if (!mounted) return;
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.nunito()),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      context.read<CommunityProvider>().fetchMyCommunities();
    }
  }

  Future<void> _handleLeave(CommunityModel community) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Keluar dari komunitas?',
            style: GoogleFonts.comfortaa(fontWeight: FontWeight.bold)),
        content: Text(
          'Kamu akan keluar dari ${community.name}.',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.nunito()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text('Keluar', style: GoogleFonts.nunito(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<CommunityProvider>().leaveCommunity(community.id);
    }
  }
}

// ---------------------------------------------------------------------------
// Tab: Semua Komunitas
// ---------------------------------------------------------------------------

class _AllCommunitiesTab extends StatelessWidget {
  final CommunityProvider provider;
  final bool isAuthenticated;
  final VoidCallback onRetry;
  final Future<void> Function(CommunityModel) onJoin;
  final Future<void> Function(CommunityModel) onLeave;

  const _AllCommunitiesTab({
    required this.provider,
    required this.isAuthenticated,
    required this.onRetry,
    required this.onJoin,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return _ErrorView(message: provider.error!, onRetry: onRetry);
    }
    if (provider.communities.isEmpty) {
      return _EmptySearchView(query: provider.searchQuery);
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchCommunities(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount:
            provider.communities.length + (isAuthenticated ? 0 : 1),
        itemBuilder: (context, index) {
          // Login CTA di bawah list jika belum login
          if (!isAuthenticated && index == provider.communities.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _LoginCta(),
            );
          }
          final community = provider.communities[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CommunityCard(
              community: community,
              isAuthenticated: isAuthenticated,
              onJoin: () => onJoin(community),
              onLeave: () => onLeave(community),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab: Komunitas Saya
// ---------------------------------------------------------------------------

class _MyCommunitiesTab extends StatelessWidget {
  final CommunityProvider provider;
  final bool isAuthenticated;
  final Future<void> Function(CommunityModel) onLeave;
  final VoidCallback onGoToAll;

  const _MyCommunitiesTab({
    required this.provider,
    required this.isAuthenticated,
    required this.onLeave,
    required this.onGoToAll,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAuthenticated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.login_rounded,
                  size: 56, color: AppColors.primaryPastel),
              const SizedBox(height: 16),
              Text(
                'Masuk untuk melihat\nkomunitas kamu',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    color: AppColors.textLight, fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Masuk', style: GoogleFonts.nunito()),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.myCommunities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.groups_outlined,
                  size: 56, color: AppColors.primaryPastel),
              const SizedBox(height: 16),
              Text(
                'Kamu belum bergabung\nke komunitas apapun',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    color: AppColors.textLight, fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onGoToAll,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text('Cari Komunitas', style: GoogleFonts.nunito()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchMyCommunities(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: provider.myCommunities.length,
        itemBuilder: (context, index) {
          final m = provider.myCommunities[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CommunityCard(
              community: m.community,
              isAuthenticated: true,
              role: m.role,
              onLeave: () => onLeave(m.community),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search Bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search_rounded,
              color: AppColors.textLight, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.nunito(
                  fontSize: 14, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Cari komunitas...',
                hintStyle: GoogleFonts.nunito(
                    color: AppColors.textLight, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textLight),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Community Card
// ---------------------------------------------------------------------------

class _CommunityCard extends StatelessWidget {
  final CommunityModel community;
  final bool isAuthenticated;
  final String? role;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;

  const _CommunityCard({
    required this.community,
    required this.isAuthenticated,
    this.role,
    this.onJoin,
    this.onLeave,
  });

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(community: community),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isJoined = community.isJoined;
    final isPending = community.isPending;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isJoined ? AppColors.primaryPastel : AppColors.divider,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: community.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(community.logoUrl!,
                            fit: BoxFit.cover),
                      )
                    : const Icon(Icons.park_rounded,
                        color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            community.name,
                            style: GoogleFonts.comfortaa(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (isJoined && role != null) _RoleBadge(role: role!),
                      ],
                    ),
                    if (community.location != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.textLight),
                          const SizedBox(width: 3),
                          Text(
                            community.location!,
                            style: GoogleFonts.nunito(
                                fontSize: 12, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (community.description != null) ...[
            const SizedBox(height: 10),
            Text(
              community.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textMedium, height: 1.5),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.people_alt_rounded,
                  size: 14, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(
                '${community.memberCount} anggota',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: community.isPublic
                      ? AppColors.primarySurface
                      : AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  community.isPublic ? 'Publik' : 'Privat',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: community.isPublic
                        ? AppColors.primary
                        : AppColors.secondary,
                  ),
                ),
              ),
              const Spacer(),
              if (isJoined)
                _OutlineButton(
                    label: 'Keluar',
                    color: AppColors.textLight,
                    onTap: onLeave)
              else if (isPending)
                _OutlineButton(
                    label: 'Menunggu',
                    color: AppColors.secondary,
                    onTap: null)
              else
                _FillButton(label: 'Bergabung', onTap: onJoin),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'ADMIN' || role == 'OWNER';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            isAdmin ? AppColors.secondarySurface : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role == 'OWNER'
            ? 'Owner'
            : role == 'ADMIN'
                ? 'Admin'
                : 'Anggota',
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isAdmin ? AppColors.secondary : AppColors.primary,
        ),
      ),
    );
  }
}

class _FillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _FillButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.white)),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _OutlineButton(
      {required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / Error / Login CTA
// ---------------------------------------------------------------------------

class _EmptySearchView extends StatelessWidget {
  final String query;
  const _EmptySearchView({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 56, color: AppColors.primaryPastel),
            const SizedBox(height: 12),
            Text(
              query.isNotEmpty
                  ? 'Tidak ada komunitas untuk\n"$query"'
                  : 'Belum ada komunitas',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.nunito(color: AppColors.textLight, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 48, color: AppColors.primaryPastel),
          const SizedBox(height: 12),
          Text(message,
              style: GoogleFonts.nunito(color: AppColors.textLight)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: Text('Coba Lagi',
                style: GoogleFonts.nunito(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _LoginCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryPastel),
      ),
      child: Row(
        children: [
          const Icon(Icons.login_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Masuk untuk bergabung ke komunitas',
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Masuk',
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
